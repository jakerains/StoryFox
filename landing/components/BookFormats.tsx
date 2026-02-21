"use client";

import { motion } from "framer-motion";
import { fadeUpVariants, staggerContainer } from "@/lib/motion";

const formats = [
  {
    name: "Standard Square",
    dimensions: '8.5" × 8.5"',
    width: 100,
    height: 100,
    delay: 0,
  },
  {
    name: "Portrait",
    dimensions: '8.5" × 11"',
    width: 80,
    height: 110,
    delay: 0.4,
  },
  {
    name: "Landscape",
    dimensions: '11" × 8.5"',
    width: 130,
    height: 90,
    delay: 0.8,
  },
  {
    name: "Small Square",
    dimensions: '6" × 6"',
    width: 72,
    height: 72,
    delay: 1.2,
  },
];

export function BookFormats() {
  return (
    <section id="formats" className="relative py-20 sm:py-28">
      <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="mb-16 text-center"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
          variants={fadeUpVariants}
        >
          <h2 className="section-title mb-4 font-serif font-bold text-sj-text">
            Four Book Formats
          </h2>
          <p className="mx-auto max-w-xl text-lg text-sj-secondary">
            Professional print dimensions for every type of story.
          </p>
        </motion.div>

        <motion.div
          className="flex flex-col items-center"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.15 }}
        >
          {/* Book shapes on shelf */}
          <div className="flex items-end justify-center gap-4 pb-4 scale-[0.7] sm:scale-100 sm:gap-12 md:gap-16 origin-bottom">
            {formats.map((format) => (
              <motion.div
                key={format.name}
                variants={fadeUpVariants}
                className="flex flex-col items-center"
              >
                {/* Floating book shape */}
                <motion.div
                  animate={{ y: [-4, 4, -4] }}
                  transition={{
                    duration: 4,
                    repeat: Infinity,
                    ease: "easeInOut",
                    delay: format.delay,
                  }}
                  className="rounded-lg"
                  style={{
                    width: format.width,
                    height: format.height,
                    background: `linear-gradient(145deg, var(--sj-card), color-mix(in srgb, var(--sj-highlight) 12%, var(--sj-card)))`,
                    boxShadow: `
                      inset -3px 0 6px rgba(0,0,0,0.04),
                      inset 0 1px 0 rgba(255,255,255,0.4),
                      0 4px 16px rgba(0,0,0,0.08),
                      0 1px 3px rgba(0,0,0,0.06)
                    `,
                    border: `1px solid color-mix(in srgb, var(--sj-border) 40%, transparent)`,
                  }}
                >
                  {/* Page lines */}
                  <div
                    className="h-full w-full rounded-lg opacity-[0.03]"
                    style={{
                      backgroundImage: `repeating-linear-gradient(0deg, transparent, transparent 7px, var(--sj-text) 7px, var(--sj-text) 8px)`,
                      backgroundPosition: "8px 10px",
                      backgroundSize: `calc(100% - 16px) calc(100% - 20px)`,
                      backgroundRepeat: "no-repeat",
                    }}
                  />
                </motion.div>
              </motion.div>
            ))}
          </div>

          {/* Bookshelf */}
          <div className="bookshelf-line w-full max-w-[280px] sm:max-w-lg" />

          {/* Labels below shelf */}
          <div className="mt-2 flex items-start justify-center gap-3 scale-[0.7] sm:scale-100 sm:mt-6 sm:gap-12 md:gap-16 origin-top">
            {formats.map((format) => (
              <motion.div
                key={format.name}
                variants={fadeUpVariants}
                className="flex flex-col items-center text-center"
                style={{ width: format.width }}
              >
                <h3 className="font-serif text-sm font-semibold text-sj-text sm:text-base">
                  {format.name}
                </h3>
                <p className="mt-0.5 font-sans text-xs text-sj-muted">
                  {format.dimensions}
                </p>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
