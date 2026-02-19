"use client";

import { motion } from "framer-motion";
import { fadeUpVariants } from "@/lib/motion";

export function SafetyDisclaimer() {
  return (
    <section className="relative py-12 sm:py-16">
      <div className="mx-auto max-w-3xl px-4 sm:px-6 lg:px-8">
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
          variants={fadeUpVariants}
          className="rounded-2xl border border-sj-border/25 bg-[var(--sj-card)]/40 px-8 py-7 backdrop-blur-sm"
        >
          <div className="flex items-start gap-4">
            <div className="mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-sj-gold/10 text-base">
              ℹ️
            </div>
            <div className="space-y-3">
              <h3 className="font-serif text-base font-semibold text-sj-text">
                A Note on Apple&apos;s On-Device Model
              </h3>
              <div className="space-y-2.5 text-sm leading-relaxed text-sj-secondary">
                <p>
                  StoryJuicer was built around a simple idea: powerful AI models are
                  already on your Mac — so let&apos;s use them. Apple Intelligence
                  makes it possible to generate entire storybooks without an internet
                  connection, without an account, and without sending your
                  children&apos;s stories to anyone&apos;s servers. That&apos;s exactly
                  what we set out to build.
                </p>
                <p>
                  However, Apple&apos;s on-device model includes strict content safety
                  filters designed to prevent inappropriate material from being
                  generated. While this is an important safeguard, the filtering can be
                  overly conservative with creative content — flagging perfectly
                  innocent story pages more often than we&apos;d like. StoryJuicer
                  automatically retries with adjusted phrasing when this happens, and
                  most pages will generate successfully. But in some cases, the
                  on-device model may still decline a prompt despite multiple attempts.
                </p>
                <p>
                  When this happens, we recommend connecting a{" "}
                  <a
                    href="#huggingface"
                    className="font-medium text-sj-coral underline decoration-sj-coral/30 underline-offset-2 transition-colors hover:decoration-sj-coral"
                  >
                    free Hugging Face account
                  </a>
                  . The cloud models provide significantly more flexibility for
                  creative storytelling while still keeping the experience simple and
                  completely free.
                </p>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
