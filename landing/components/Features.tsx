"use client";

import { motion } from "framer-motion";
import { scaleInVariants, staggerContainer } from "@/lib/motion";
import { GlassCard } from "./GlassCard";

const features = [
  {
    icon: "🔒",
    title: "Works Offline",
    description:
      "Runs entirely on your device. No internet, no accounts. Your stories never leave your Mac.",
    color: "var(--sj-mint)",
  },
  {
    icon: "🖨️",
    title: "Print-Ready PDF",
    description:
      "Exports at 300 DPI in real book dimensions. Take the PDF to a print shop or print it at home.",
    color: "var(--sj-gold)",
  },
  {
    icon: "🛡️",
    title: "Safe for Kids",
    description:
      "Content filters keep stories age-appropriate for ages 3\u20138. You can also set audience mode to \u201CKid\u201D for simpler vocabulary.",
    color: "var(--sj-coral)",
  },
  {
    icon: "📖",
    title: "Choose Your Length",
    description:
      "3 pages for a quick bedtime story, 20 for a full adventure. You set the page count.",
    color: "var(--sj-lavender)",
  },
  {
    icon: "🔄",
    title: "Redo Any Page",
    description:
      "Don't like a page? Regenerate just that page's text or illustration without restarting the whole book.",
    color: "var(--sj-sky)",
  },
  {
    icon: "📚",
    title: "Save Your Library",
    description:
      "Books save automatically. Re-read, export, or share them whenever you want.",
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
            What&apos;s Built In
          </h2>
          <p className="mx-auto max-w-xl text-lg text-sj-secondary">
            Print-quality storybooks, offline by default, with tools to tweak every page.
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
