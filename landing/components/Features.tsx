"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { fadeUpVariants, scaleInVariants, staggerContainer } from "@/lib/motion";

const heroFeatures = [
  {
    image: "/images/feature-offline.png",
    title: "Works Offline",
    description:
      "Runs entirely on your device. No internet, no accounts. Your stories never leave your Mac.",
    gradient: "from-[var(--sj-mint)]/6 to-transparent",
    accentColor: "var(--sj-mint)",
  },
  {
    image: "/images/feature-print.png",
    title: "Print-Ready PDF",
    description:
      "Exports at 300 DPI in real book dimensions. Take the PDF to a print shop or print it at home.",
    gradient: "from-[var(--sj-gold)]/6 to-transparent",
    accentColor: "var(--sj-gold)",
  },
];

const compactFeatures = [
  {
    image: "/images/feature-safe.png",
    title: "Safe for Kids",
    description:
      'Content filters keep stories age-appropriate for ages 3\u20138. Set audience mode to "Kid" for simpler vocabulary.',
    color: "var(--sj-coral)",
  },
  {
    image: "/images/feature-length.png",
    title: "Choose Your Length",
    description:
      "3 pages for a quick bedtime story, 20 for a full adventure. You set the page count.",
    color: "var(--sj-lavender)",
  },
  {
    image: "/images/feature-redo.png",
    title: "Redo Any Page",
    description:
      "Regenerate just that page\u2019s text or illustration without restarting the whole book.",
    color: "var(--sj-sky)",
  },
  {
    image: "/images/feature-library.png",
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
          className="flex flex-col gap-5"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.1 }}
        >
          {/* Hero features — two large cards with prominent images */}
          <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
            {heroFeatures.map((feature) => (
              <motion.div key={feature.title} variants={fadeUpVariants}>
                <div
                  className={`bento-hero flex flex-col items-center gap-5 bg-gradient-to-br sm:flex-row sm:items-start ${feature.gradient}`}
                >
                  {/* Image — large rounded showcase */}
                  <div
                    className="shrink-0 overflow-hidden rounded-2xl"
                    style={{
                      boxShadow: `0 6px 20px color-mix(in srgb, ${feature.accentColor} 15%, transparent)`,
                    }}
                  >
                    <Image
                      src={feature.image}
                      alt={feature.title}
                      width={140}
                      height={140}
                      className="h-[120px] w-[120px] object-cover sm:h-[140px] sm:w-[140px]"
                    />
                  </div>

                  {/* Text */}
                  <div className="text-center sm:text-left">
                    <h3 className="mb-2 font-serif text-2xl font-semibold text-sj-text">
                      {feature.title}
                    </h3>
                    <p className="max-w-sm text-base leading-relaxed text-sj-secondary">
                      {feature.description}
                    </p>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          {/* Compact features — image + text rows */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {compactFeatures.map((feature) => (
              <motion.div key={feature.title} variants={fadeUpVariants}>
                <div className="bento-compact">
                  <div
                    className="shrink-0 overflow-hidden rounded-xl"
                    style={{
                      boxShadow: `0 4px 12px color-mix(in srgb, ${feature.color} 10%, transparent)`,
                    }}
                  >
                    <Image
                      src={feature.image}
                      alt={feature.title}
                      width={64}
                      height={64}
                      className="h-16 w-16 object-cover"
                    />
                  </div>
                  <div>
                    <h3 className="mb-1 font-serif text-base font-semibold text-sj-text">
                      {feature.title}
                    </h3>
                    <p className="text-sm leading-relaxed text-sj-secondary">
                      {feature.description}
                    </p>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
