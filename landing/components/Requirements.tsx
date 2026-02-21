"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { fadeUpVariants, staggerContainer } from "@/lib/motion";

const requirements = [
  {
    image: "/images/req-macos.png",
    title: "macOS 26",
    subtitle: "Tahoe",
    description: "Requires the latest macOS with Apple Intelligence.",
    color: "var(--sj-coral)",
  },
  {
    image: "/images/req-silicon.png",
    title: "Apple Silicon",
    subtitle: "M1 or later",
    description: "Needs the Neural Engine in M1 or newer chips.",
    color: "var(--sj-gold)",
  },
  {
    image: "/images/req-apple-intelligence.png",
    title: "Apple Intelligence",
    subtitle: "Enabled",
    description: "The on-device text and image generation runs through Apple Intelligence.",
    color: "var(--sj-lavender)",
  },
];

export function Requirements() {
  return (
    <section id="requirements" className="relative py-14 sm:py-20">
      {/* Ambient glow */}
      <div className="glow-amber pointer-events-none absolute left-1/2 top-0 h-[300px] w-[500px] -translate-x-1/2" />

      <div className="mx-auto max-w-4xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="mb-10 text-center"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
          variants={fadeUpVariants}
        >
          <h2 className="section-title mb-3 font-serif font-bold text-sj-text">
            What You Need
          </h2>
          <p className="mx-auto max-w-md text-lg text-sj-secondary">
            Three things, all free.
          </p>
        </motion.div>

        <motion.div
          className="grid grid-cols-1 gap-4 sm:grid-cols-3"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.2 }}
          variants={staggerContainer}
        >
          {requirements.map((req) => (
            <motion.div
              key={req.title}
              variants={fadeUpVariants}
              className="flex flex-col items-center rounded-2xl border p-5 text-center"
              style={{
                borderColor: `color-mix(in srgb, ${req.color} 20%, transparent)`,
                background: `color-mix(in srgb, var(--sj-card) 30%, transparent)`,
              }}
            >
              <div
                className="mb-3 overflow-hidden rounded-xl"
                style={{
                  boxShadow: `0 4px 16px color-mix(in srgb, ${req.color} 15%, transparent)`,
                }}
              >
                <Image
                  src={req.image}
                  alt={req.title}
                  width={80}
                  height={80}
                  className="h-20 w-20 object-cover"
                />
              </div>

              <div className="flex items-baseline gap-1.5">
                <span className="font-serif text-base font-bold text-sj-text">
                  {req.title}
                </span>
                <span
                  className="text-xs font-medium"
                  style={{ color: req.color }}
                >
                  ({req.subtitle})
                </span>
              </div>

              <p className="mt-1 text-xs leading-relaxed text-sj-secondary">
                {req.description}
              </p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
