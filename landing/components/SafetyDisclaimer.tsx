"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { fadeUpVariants, staggerContainer } from "@/lib/motion";

export function SafetyDisclaimer() {
  return (
    <section className="relative py-14 sm:py-20">
      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.15 }}
          variants={staggerContainer}
          className="overflow-hidden rounded-3xl border border-sj-border/30 bg-[var(--sj-card)]/50"
        >
          {/* Banner image — full bleed inside the card */}
          <motion.div variants={fadeUpVariants}>
            <Image
              src="/images/disclaimer-banner.png"
              alt="A fox sitting at a cozy desk, surrounded by a warm privacy shield glow"
              width={1536}
              height={1024}
              className="h-36 w-full object-cover sm:h-52 md:h-72"
            />
          </motion.div>

          {/* Divider */}
          <div className="h-px bg-sj-border/20" />

          {/* Text content — clear area below the image */}
          <motion.div
            variants={fadeUpVariants}
            className="px-6 py-7 sm:px-10 sm:py-9"
          >
            <h3 className="mb-4 font-serif text-xl font-semibold text-sj-text">
              A Note on Apple&apos;s On-Device Model
            </h3>

            <div className="space-y-3 text-sm leading-relaxed text-sj-secondary">
              <p>
                StoryFox exists because Apple already put capable AI models on
                your Mac. Apple Intelligence makes it possible to generate entire
                storybooks without an internet connection and without an account.
                Your children&apos;s stories never leave your device.
              </p>
              <p>
                However, Apple&apos;s on-device model has strict content safety
                filters. These are important, but they can be overly conservative
                with creative content, flagging perfectly innocent story pages more
                often than we&apos;d like. StoryFox automatically retries with
                adjusted phrasing when this happens, and most pages generate
                successfully. But sometimes the on-device model still declines a
                prompt despite multiple attempts.
              </p>
              <p>
                When this happens, we recommend connecting a{" "}
                <a
                  href="#huggingface"
                  className="font-medium text-sj-coral underline decoration-sj-coral/30 underline-offset-2 transition-colors hover:decoration-sj-coral"
                >
                  free Hugging Face account
                </a>
                . The cloud models are less restrictive with creative content and
                still completely free.
              </p>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
