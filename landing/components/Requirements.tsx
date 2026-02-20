"use client";

import { motion } from "framer-motion";
import { fadeUpVariants, staggerContainer } from "@/lib/motion";
import { GlassCard } from "./GlassCard";

const requirements = [
  {
    icon: "🖥",
    title: "macOS 26",
    subtitle: "Tahoe",
    description: "Requires the latest macOS with Apple Intelligence.",
    color: "var(--sj-coral)",
  },
  {
    icon: "⚡",
    title: "Apple Silicon",
    subtitle: "M1 or later",
    description: "Needs the Neural Engine in M1 or newer chips.",
    color: "var(--sj-gold)",
  },
  {
    icon: "✨",
    title: "Apple Intelligence",
    subtitle: "Enabled",
    description: "The on-device text and image generation runs through Apple Intelligence.",
    color: "var(--sj-lavender)",
  },
];

export function Requirements() {
  return (
    <section id="requirements" className="relative py-20 sm:py-28">
      {/* Ambient glow */}
      <div className="glow-amber pointer-events-none absolute left-1/2 top-0 h-[300px] w-[500px] -translate-x-1/2" />

      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="mb-14 text-center"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
          variants={fadeUpVariants}
        >
          <h2 className="section-title mb-4 font-serif font-bold text-sj-text">
            What You Need
          </h2>
          <p className="mx-auto max-w-md text-lg text-sj-secondary">
            Three things, all free.
          </p>
        </motion.div>

        <motion.div
          className="grid grid-cols-1 gap-5 sm:grid-cols-3"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.2 }}
        >
          {requirements.map((req) => (
            <motion.div key={req.title} variants={fadeUpVariants}>
              <GlassCard className="flex h-full flex-col items-center p-7 text-center" hover>
                {/* Colored icon ring */}
                <div
                  className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl text-2xl"
                  style={{
                    backgroundColor: `color-mix(in srgb, ${req.color} 14%, transparent)`,
                    boxShadow: `0 0 0 1px color-mix(in srgb, ${req.color} 20%, transparent)`,
                  }}
                >
                  {req.icon}
                </div>

                {/* Title + subtitle */}
                <h3 className="font-serif text-lg font-bold text-sj-text">
                  {req.title}
                </h3>
                <span
                  className="mb-3 mt-1 inline-block rounded-full px-2.5 py-0.5 text-xs font-semibold tracking-wide"
                  style={{
                    backgroundColor: `color-mix(in srgb, ${req.color} 10%, transparent)`,
                    color: req.color,
                  }}
                >
                  {req.subtitle}
                </span>

                {/* Description */}
                <p className="text-sm leading-relaxed text-sj-secondary">
                  {req.description}
                </p>
              </GlassCard>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
