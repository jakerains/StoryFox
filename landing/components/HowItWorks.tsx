"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { fadeUpVariants, staggerContainer } from "@/lib/motion";

const steps = [
  {
    number: 1,
    title: "Describe",
    description:
      '"A curious fox building a moonlight library in the forest"',
    image: "/images/step-describe.png",
    color: "var(--sj-coral)",
  },
  {
    number: 2,
    title: "Customize",
    description: "Pick page count, book format, and illustration style",
    image: "/images/step-customize.png",
    color: "var(--sj-gold)",
  },
  {
    number: 3,
    title: "Generate",
    description: "Text streams live, then illustrations paint concurrently",
    image: "/images/step-generate.png",
    color: "var(--sj-mint)",
  },
  {
    number: 4,
    title: "Export",
    description: "Flip through pages, then save as 300 DPI print-ready PDF",
    image: "/images/step-export.png",
    color: "var(--sj-sky)",
  },
];

export function HowItWorks() {
  return (
    <section id="how-it-works" className="paper-texture relative py-20 sm:py-28">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="mb-16 text-center"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
          variants={fadeUpVariants}
        >
          <h2 className="section-title mb-4 font-serif font-bold text-sj-text">
            How It Works
          </h2>
          <p className="mx-auto max-w-xl text-lg text-sj-secondary">
            From idea to illustrated storybook in four simple steps.
          </p>
        </motion.div>

        {/* Desktop: horizontal card grid */}
        <motion.div
          className="relative hidden lg:block"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.15 }}
        >
          {/* Connecting dashed gradient line — runs behind the number badges */}
          <div className="absolute left-0 right-0" style={{ top: 88 }}>
            <svg
              className="w-full"
              height="4"
              preserveAspectRatio="none"
              viewBox="0 0 1000 4"
            >
              <defs>
                <linearGradient id="timeline-grad" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="var(--sj-coral)" stopOpacity="0.5" />
                  <stop offset="33%" stopColor="var(--sj-gold)" stopOpacity="0.5" />
                  <stop offset="66%" stopColor="var(--sj-mint)" stopOpacity="0.5" />
                  <stop offset="100%" stopColor="var(--sj-sky)" stopOpacity="0.5" />
                </linearGradient>
              </defs>
              <line
                x1="60"
                y1="2"
                x2="940"
                y2="2"
                stroke="url(#timeline-grad)"
                strokeWidth="2"
                strokeDasharray="8 6"
              />
            </svg>
          </div>

          {/* Steps */}
          <div className="relative grid grid-cols-4 gap-6">
            {steps.map((step) => (
              <motion.div
                key={step.number}
                variants={fadeUpVariants}
                className="flex flex-col items-center text-center"
              >
                {/* Illustration card */}
                <div className="relative mb-4 w-full">
                  <div
                    className="overflow-hidden rounded-2xl border"
                    style={{
                      borderColor: `color-mix(in srgb, ${step.color} 25%, transparent)`,
                      boxShadow: `0 8px 24px color-mix(in srgb, ${step.color} 12%, transparent)`,
                    }}
                  >
                    <Image
                      src={step.image}
                      alt={step.title}
                      width={280}
                      height={280}
                      className="aspect-square w-full object-cover"
                    />
                  </div>

                  {/* Step number badge — floats at bottom center, overlapping the image edge */}
                  <div
                    className="absolute -bottom-4 left-1/2 z-10 flex h-8 w-8 -translate-x-1/2 items-center justify-center rounded-full text-sm font-bold text-white shadow-md"
                    style={{ backgroundColor: step.color }}
                  >
                    {step.number}
                  </div>
                </div>

                {/* Title */}
                <h3 className="mb-1.5 mt-3 font-serif text-xl font-semibold text-sj-text">
                  {step.title}
                </h3>

                {/* Description */}
                <p className="max-w-[220px] text-sm leading-relaxed text-sj-secondary">
                  {step.description}
                </p>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* Mobile: vertical cards */}
        <motion.div
          className="relative lg:hidden"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.1 }}
        >
          <div className="flex flex-col gap-8">
            {steps.map((step) => (
              <motion.div
                key={step.number}
                variants={fadeUpVariants}
                className="flex items-start gap-4"
              >
                {/* Illustration — rounded rectangle, not circle */}
                <div
                  className="shrink-0 overflow-hidden rounded-xl border"
                  style={{
                    borderColor: `color-mix(in srgb, ${step.color} 25%, transparent)`,
                    boxShadow: `0 4px 12px color-mix(in srgb, ${step.color} 10%, transparent)`,
                  }}
                >
                  <Image
                    src={step.image}
                    alt={step.title}
                    width={96}
                    height={96}
                    className="h-24 w-24 object-cover"
                  />
                </div>

                {/* Text */}
                <div className="pt-1">
                  <div className="mb-1 flex items-center gap-2">
                    <span
                      className="flex h-6 w-6 items-center justify-center rounded-full text-xs font-bold text-white"
                      style={{ backgroundColor: step.color }}
                    >
                      {step.number}
                    </span>
                    <h3 className="font-serif text-lg font-semibold text-sj-text">
                      {step.title}
                    </h3>
                  </div>
                  <p className="text-sm leading-relaxed text-sj-secondary">
                    {step.description}
                  </p>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
