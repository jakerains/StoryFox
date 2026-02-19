"use client";

import { motion } from "framer-motion";
import { scaleInVariants, staggerContainer } from "@/lib/motion";
import { GlassCard } from "./GlassCard";

const features = [
  {
    icon: "🔒",
    title: "Works Offline",
    description:
      "Everything runs on your device by default. No internet needed, no accounts required. Your stories stay private.",
    color: "var(--sj-mint)",
  },
  {
    icon: "🖨️",
    title: "Print-Ready PDF",
    description:
      "Export at 300 DPI with professional book dimensions. Ready to print at home or a print shop.",
    color: "var(--sj-gold)",
  },
  {
    icon: "🛡️",
    title: "Safe for Kids",
    description:
      "Built-in safety guardrails ensure every story is age-appropriate for ages 3–8. Peace of mind for parents.",
    color: "var(--sj-coral)",
  },
  {
    icon: "📖",
    title: "Choose Your Length",
    description:
      "Create anything from a quick 3-page bedtime story to a full 20-page adventure. You pick the page count.",
    color: "var(--sj-lavender)",
  },
  {
    icon: "🔄",
    title: "Redo Any Page",
    description:
      "Not happy with a page? Regenerate just the text or illustration individually — no need to start over.",
    color: "var(--sj-sky)",
  },
  {
    icon: "📚",
    title: "Save Your Library",
    description:
      "All your storybooks are saved automatically. Come back anytime to re-read, export, or share them.",
    color: "var(--sj-gold)",
  },
];

export function Features() {
  return (
    <section id="features" className="relative py-20 sm:py-28">
      {/* Subtle ambient glow */}
      <div className="glow-peach pointer-events-none absolute right-0 top-1/4 h-[400px] w-[400px]" />

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="mb-16 text-center"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
          variants={scaleInVariants}
        >
          <h2 className="section-title mb-4 font-serif font-bold text-sj-text">
            Everything You Need
          </h2>
          <p className="mx-auto max-w-xl text-lg text-sj-secondary">
            Professional-quality storybooks with powerful features built right
            in.
          </p>
        </motion.div>

        <motion.div
          className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.1 }}
        >
          {features.map((feature) => (
            <motion.div key={feature.title} variants={scaleInVariants}>
              <GlassCard className="flex h-full flex-col p-6" hover>
                <div
                  className="mb-4 flex h-11 w-11 items-center justify-center rounded-full text-2xl"
                  style={{
                    backgroundColor: `color-mix(in srgb, ${feature.color} 12%, transparent)`,
                  }}
                >
                  {feature.icon}
                </div>

                <h3 className="mb-2 font-serif text-lg font-semibold text-sj-text">
                  {feature.title}
                </h3>

                <p className="text-sm leading-relaxed text-sj-secondary">
                  {feature.description}
                </p>
              </GlassCard>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
