import Foundation

#if os(macOS)

enum DiffusersWorkerMode: String, Sendable {
    case healthCheck = "health"
    case prewarm = "prewarm"
    case generate = "generate"
}

struct DiffusersWorkerEvent: Codable, Sendable {
    let event: String
    let message: String?
    let error: String?
    let outputPath: String?
    let progress: Double?

    enum CodingKeys: String, CodingKey {
        case event
        case message
        case error
        case outputPath = "output_path"
        case progress
    }
}

struct DiffusersGenerateRequest: Codable, Sendable {
    let modelID: String
    let prompt: String
    let width: Int
    let height: Int
    let steps: Int
    let guidanceScale: Double
    let seed: UInt64?
    let outputPath: String

    enum CodingKeys: String, CodingKey {
        case modelID = "model_id"
        case prompt
        case width
        case height
        case steps
        case guidanceScale = "guidance_scale"
        case seed
        case outputPath = "output_path"
    }
}

struct DiffusersRuntimeStatus: Sendable {
    let runtimeInstalled: Bool
    let dependenciesCurrent: Bool
    let modelCached: Bool
    let snapshotCount: Int
    let cacheByteCount: Int64
    let prewarmed: Bool
    let prewarmDate: Date?
}

enum DiffusersRuntimeError: LocalizedError {
    case pythonNotFound
    case resourceMissing(String)
    case commandFailed(command: String, output: String)
    case processTimedOut(command: String)
    case workerError(String)
    case invalidWorkerOutput
    case imageOutputMissing(String)

    var errorDescription: String? {
        switch self {
        case .pythonNotFound:
            return "Python 3.11+ is required for local Diffusers runtime."
        case .resourceMissing(let name):
            return "Required Diffusers runtime resource is missing: \(name)"
        case .commandFailed(let command, let output):
            return "Command failed (\(command)): \(output)"
        case .processTimedOut(let command):
            return "Process timed out while running \(command)."
        case .workerError(let message):
            return message
        case .invalidWorkerOutput:
            return "Diffusers worker returned an invalid response."
        case .imageOutputMissing(let path):
            return "Diffusers worker did not create an image at \(path)."
        }
    }
}

actor DiffusersRuntimeManager {
    struct RuntimeLayout: Sendable {
        let runtimeRootURL: URL
        let cacheURL: URL
        let pythonExecutableURL: URL
        let requirementsURL: URL
        let workerScriptURL: URL
    }

    static let shared = DiffusersRuntimeManager()
    static let defaultAlias = "default"

    private static let dependencyStamp = "diffusers=0.36.0;torch=2.10.0"
    private let fileManager = FileManager.default

    func runtimeStatus(
        alias rawAlias: String,
        modelID rawModelID: String
    ) throws -> DiffusersRuntimeStatus {
        let layout = try runtimeLayout(alias: rawAlias)
        let runtimeInstalled = fileManager.fileExists(atPath: layout.pythonExecutableURL.path)

        let stampURL = layout.runtimeRootURL.appendingPathComponent(".deps-version")
        let installedStamp = try? String(contentsOf: stampURL, encoding: .utf8)
        let dependenciesCurrent = installedStamp?.trimmingCharacters(in: .whitespacesAndNewlines) == Self.dependencyStamp

        let modelID = normalizedModelID(rawModelID)
        let cacheRoot = hubModelCacheDirectory(layout: layout, modelID: modelID)
        let snapshotsRoot = cacheRoot.appendingPathComponent("snapshots", isDirectory: true)

        let snapshotCount = snapshotDirectoryCount(at: snapshotsRoot)
        let cacheByteCount = directoryByteCount(at: cacheRoot)
        let modelCached = snapshotCount > 0 || cacheByteCount > 0

        let markerURL = prewarmMarkerURL(layout: layout, modelID: modelID)
        let prewarmDate = try? readMarkerDate(at: markerURL)

        return DiffusersRuntimeStatus(
            runtimeInstalled: runtimeInstalled,
            dependenciesCurrent: dependenciesCurrent,
            modelCached: modelCached,
            snapshotCount: snapshotCount,
            cacheByteCount: cacheByteCount,
            prewarmed: prewarmDate != nil,
            prewarmDate: prewarmDate
        )
    }

    func runtimeLayout(alias rawAlias: String) throws -> RuntimeLayout {
        let alias = normalizeAlias(rawAlias)

        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
              let cacheRoot = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw DiffusersRuntimeError.resourceMissing("Application Support paths")
        }

        let runtimeRootURL = appSupport
            .appendingPathComponent("StoryJuicer", isDirectory: true)
            .appendingPathComponent("Diffusers", isDirectory: true)
            .appendingPathComponent(alias, isDirectory: true)

        let cacheURL = cacheRoot
            .appendingPathComponent("StoryJuicer", isDirectory: true)
            .appendingPathComponent("Diffusers", isDirectory: true)
            .appendingPathComponent(alias, isDirectory: true)

        return RuntimeLayout(
            runtimeRootURL: runtimeRootURL,
            cacheURL: cacheURL,
            pythonExecutableURL: runtimeRootURL
                .appendingPathComponent("venv", isDirectory: true)
                .appendingPathComponent("bin", isDirectory: true)
                .appendingPathComponent("python"),
            requirementsURL: try resolveResourceURL(
                filename: "diffusers-requirements",
                fileExtension: "txt"
            ),
            workerScriptURL: try resolveResourceURL(
                filename: "diffusers_worker",
                fileExtension: "py"
            )
        )
    }

    func ensureRuntimeInstalled(
        alias rawAlias: String,
        onStatus: @Sendable @escaping (String) -> Void = { _ in }
    ) async throws {
        let layout = try runtimeLayout(alias: rawAlias)
        try fileManager.createDirectory(at: layout.runtimeRootURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: layout.cacheURL, withIntermediateDirectories: true)

        let python3Path = try await discoverSystemPython()

        if !fileManager.fileExists(atPath: layout.pythonExecutableURL.path) {
            onStatus("Creating managed Python environment...")
            _ = try await runBlockingProcess(
                executablePath: python3Path,
                arguments: ["-m", "venv", layout.runtimeRootURL.appendingPathComponent("venv").path],
                timeout: 180,
                captureOutput: true
            )
        }

        let stampURL = layout.runtimeRootURL.appendingPathComponent(".deps-version")
        let installedStamp = try? String(contentsOf: stampURL, encoding: .utf8)
        if installedStamp?.trimmingCharacters(in: .whitespacesAndNewlines) == Self.dependencyStamp {
            return
        }

        onStatus("Installing pinned Diffusers dependencies...")
        _ = try await runBlockingProcess(
            executablePath: layout.pythonExecutableURL.path,
            arguments: ["-m", "pip", "install", "--upgrade", "pip"],
            timeout: 420,
            captureOutput: true
        )

        _ = try await runBlockingProcess(
            executablePath: layout.pythonExecutableURL.path,
            arguments: ["-m", "pip", "install", "--requirement", layout.requirementsURL.path],
            timeout: 1800,
            captureOutput: true
        )

        try Self.dependencyStamp.write(to: stampURL, atomically: true, encoding: .utf8)
    }

    func healthCheck(
        alias rawAlias: String,
        modelID: String,
        hfToken: String?,
        onStatus: @Sendable @escaping (String) -> Void = { _ in }
    ) async throws {
        let layout = try runtimeLayout(alias: rawAlias)
        let events = try await runWorker(
            mode: .healthCheck,
            layout: layout,
            hfToken: hfToken,
            modelID: modelID,
            request: nil
        )

        for event in events {
            if let message = event.message, !message.isEmpty {
                onStatus(message)
            }
            if let error = event.error {
                throw DiffusersRuntimeError.workerError(error)
            }
        }
    }

    func prewarmModel(
        alias rawAlias: String,
        modelID: String,
        hfToken: String?,
        onStatus: @Sendable @escaping (String) -> Void = { _ in }
    ) async throws {
        let layout = try runtimeLayout(alias: rawAlias)
        let events = try await runWorker(
            mode: .prewarm,
            layout: layout,
            hfToken: hfToken,
            modelID: modelID,
            request: nil
        )

        for event in events {
            if let message = event.message, !message.isEmpty {
                onStatus(message)
            }
            if let error = event.error {
                throw DiffusersRuntimeError.workerError(error)
            }
        }

        try? markModelPrewarmed(layout: layout, modelID: modelID)
    }

    func generateImage(
        alias rawAlias: String,
        request: DiffusersGenerateRequest,
        hfToken: String?,
        onEvent: @Sendable @escaping (DiffusersWorkerEvent) -> Void
    ) async throws -> URL {
        let layout = try runtimeLayout(alias: rawAlias)

        let events = try await runWorker(
            mode: .generate,
            layout: layout,
            hfToken: hfToken,
            modelID: request.modelID,
            request: request
        )

        var outputPath: String?
        for event in events {
            onEvent(event)
            if let error = event.error {
                throw DiffusersRuntimeError.workerError(error)
            }
            if let workerOutput = event.outputPath, !workerOutput.isEmpty {
                outputPath = workerOutput
            }
        }

        guard let outputPath else {
            throw DiffusersRuntimeError.invalidWorkerOutput
        }

        let outputURL = URL(fileURLWithPath: outputPath)
        guard fileManager.fileExists(atPath: outputURL.path) else {
            throw DiffusersRuntimeError.imageOutputMissing(outputURL.path)
        }

        return outputURL
    }

    private func discoverSystemPython() async throws -> String {
        let result = try await runBlockingProcess(
            executablePath: "/usr/bin/env",
            arguments: ["python3", "--version"],
            timeout: 20,
            captureOutput: true
        )

        guard !result.output.isEmpty else {
            throw DiffusersRuntimeError.pythonNotFound
        }

        let which = try await runBlockingProcess(
            executablePath: "/usr/bin/which",
            arguments: ["python3"],
            timeout: 20,
            captureOutput: true
        )

        let path = which.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            throw DiffusersRuntimeError.pythonNotFound
        }
        return path
    }

    private func runWorker(
        mode: DiffusersWorkerMode,
        layout: RuntimeLayout,
        hfToken: String?,
        modelID: String,
        request: DiffusersGenerateRequest?
    ) async throws -> [DiffusersWorkerEvent] {
        let arguments = [layout.workerScriptURL.path, "--mode", mode.rawValue, "--model-id", modelID]
        var stdinData: Data?

        if let request {
            stdinData = try JSONEncoder().encode(request)
        }

        let env = workerEnvironment(layout: layout, hfToken: hfToken)
        let result = try await runBlockingProcess(
            executablePath: layout.pythonExecutableURL.path,
            arguments: arguments,
            environment: env,
            timeout: timeout(for: mode),
            captureOutput: true,
            stdinData: stdinData
        )

        if result.status != 0 {
            throw DiffusersRuntimeError.commandFailed(
                command: "diffusers worker \(mode.rawValue)",
                output: result.output
            )
        }

        let decoder = JSONDecoder()
        let lines = result.output
            .split(separator: "\n")
            .map { String($0) }

        var events: [DiffusersWorkerEvent] = []
        for line in lines {
            guard let data = line.data(using: .utf8),
                  let event = try? decoder.decode(DiffusersWorkerEvent.self, from: data) else {
                continue
            }
            events.append(event)
        }
        return events
    }

    private func timeout(for mode: DiffusersWorkerMode) -> TimeInterval {
        switch mode {
        case .healthCheck:
            return 45
        case .prewarm:
            // Initial FLUX model downloads can take several minutes.
            return 3600
        case .generate:
            return GenerationConfig.diffusersGenerationTimeoutSeconds
        }
    }

    private func workerEnvironment(layout: RuntimeLayout, hfToken: String?) -> [String: String] {
        var env: [String: String] = [
            "HF_HOME": layout.cacheURL.path,
            "HF_HUB_CACHE": layout.cacheURL.appendingPathComponent("hub", isDirectory: true).path,
            "HUGGINGFACE_HUB_CACHE": layout.cacheURL.appendingPathComponent("hub", isDirectory: true).path,
            "HF_HUB_DISABLE_PROGRESS_BARS": "1",
            "TRANSFORMERS_VERBOSITY": "error",
            "PYTORCH_ENABLE_MPS_FALLBACK": "1"
        ]
        if let hfToken, !hfToken.isEmpty {
            env["HF_TOKEN"] = hfToken
            env["HUGGINGFACE_HUB_TOKEN"] = hfToken
        }
        return env
    }

    private func normalizedModelID(_ modelID: String) -> String {
        let trimmed = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? ModelSelectionSettings.defaultDiffusersModelID : trimmed
    }

    private func hubModelCacheDirectory(layout: RuntimeLayout, modelID: String) -> URL {
        let huggingFaceSafeID = modelID.replacingOccurrences(of: "/", with: "--")
        return layout.cacheURL
            .appendingPathComponent("hub", isDirectory: true)
            .appendingPathComponent("models--\(huggingFaceSafeID)", isDirectory: true)
    }

    private func snapshotDirectoryCount(at url: URL) -> Int {
        guard let entries = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        return entries.reduce(into: 0) { count, entry in
            if let values = try? entry.resourceValues(forKeys: [.isDirectoryKey]),
               values.isDirectory == true {
                count += 1
            }
        }
    }

    private func directoryByteCount(at url: URL) -> Int64 {
        guard fileManager.fileExists(atPath: url.path),
              let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
              ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true,
                  let fileSize = values.fileSize else {
                continue
            }
            total += Int64(fileSize)
        }
        return total
    }

    private func markerSlug(for modelID: String) -> String {
        String(
            modelID
                .lowercased()
                .map { character in
                    character.isLetter || character.isNumber ? character : "_"
                }
        )
    }

    private func prewarmMarkerURL(layout: RuntimeLayout, modelID: String) -> URL {
        layout.runtimeRootURL.appendingPathComponent(
            ".model-prewarmed-\(markerSlug(for: modelID))",
            isDirectory: false
        )
    }

    private func markModelPrewarmed(layout: RuntimeLayout, modelID: String) throws {
        let markerURL = prewarmMarkerURL(layout: layout, modelID: modelID)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        try timestamp.write(to: markerURL, atomically: true, encoding: .utf8)
    }

    private func readMarkerDate(at markerURL: URL) throws -> Date? {
        guard fileManager.fileExists(atPath: markerURL.path) else {
            return nil
        }
        let raw = try String(contentsOf: markerURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

    private func resolveResourceURL(filename: String, fileExtension: String) throws -> URL {
        if let bundled = Bundle.main.url(
            forResource: filename,
            withExtension: fileExtension,
            subdirectory: "Diffusers"
        ) {
            return bundled
        }

        let localPath = URL(fileURLWithPath: fileManager.currentDirectoryPath)
            .appendingPathComponent("Resources", isDirectory: true)
            .appendingPathComponent("Diffusers", isDirectory: true)
            .appendingPathComponent("\(filename).\(fileExtension)")

        if fileManager.fileExists(atPath: localPath.path) {
            return localPath
        }

        throw DiffusersRuntimeError.resourceMissing("\(filename).\(fileExtension)")
    }

    private func normalizeAlias(_ alias: String) -> String {
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultAlias : trimmed
    }

    private func runBlockingProcess(
        executablePath: String,
        arguments: [String],
        environment: [String: String] = [:],
        timeout: TimeInterval,
        captureOutput: Bool,
        stdinData: Data? = nil
    ) async throws -> (status: Int32, output: String) {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            var fullEnvironment = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                fullEnvironment[key] = value
            }
            process.environment = fullEnvironment

            let outputPipe = Pipe()
            let stdinPipe = Pipe()

            if captureOutput {
                process.standardOutput = outputPipe
                process.standardError = outputPipe
            } else {
                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice
            }

            if stdinData != nil {
                process.standardInput = stdinPipe
            }

            try process.run()

            if let stdinData {
                stdinPipe.fileHandleForWriting.write(stdinData)
                try? stdinPipe.fileHandleForWriting.close()
            }

            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning {
                if Date() > deadline {
                    process.terminate()
                    throw DiffusersRuntimeError.processTimedOut(
                        command: ([executablePath] + arguments).joined(separator: " ")
                    )
                }
                try await Task.sleep(for: .milliseconds(100))
            }

            let outputData = captureOutput
                ? outputPipe.fileHandleForReading.readDataToEndOfFile()
                : Data()
            let output = String(data: outputData, encoding: .utf8) ?? ""

            return (process.terminationStatus, output)
        }.value
    }
}

#endif // os(macOS)
