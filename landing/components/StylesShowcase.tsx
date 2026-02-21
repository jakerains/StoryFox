"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import { fadeUpVariants, staggerContainer, fanVariants } from "@/lib/motion";

const styles = [
  {
    name: "Illustration",
    tagline: "Classic children's book — painterly brushstrokes and soft shading",
    image: "/images/style-illustration.png",
    rotation: -6,
    accentColor: "var(--sj-coral)",
  },
  {
    name: "Animation",
    tagline: "Pixar-inspired cartoon — rounded shapes and cinematic lighting",
    image: "/images/style-animation.png",
    rotation: 0,
    accentColor: "var(--sj-sky)",
  },
  {
    name: "Sketch",
    tagline: "Hand-drawn pencil lines with watercolor wash fill",
    image: "/images/style-sketch.png",
    rotation: 6,
    accentColor: "var(--sj-gold)",
  },
];

export function StylesShowcase() {
  return (
    <section id="styles" className="relative py-20 sm:py-28 overflow-hidden">
      <div className="glow-amber pointer-events-none absolute -left-32 top-0 h-[400px] w-[400px]" />

      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <motion.div
          className="mb-16 text-center"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.3 }}
          variants={fadeUpVariants}
        >
          <h2 className="section-title mb-4 font-serif font-bold text-sj-text">
            Three Distinct Styles
          </h2>
          <p className="mx-auto max-w-xl text-lg text-sj-secondary">
            Choose the perfect visual style for your story.
          </p>
        </motion.div>

        {/* Fan layout */}
        <motion.div
          className="flex items-center justify-center"
          variants={staggerContainer}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.15 }}
        >
          <div className="relative flex items-end justify-center">
            {styles.map((style, i) => (
              <motion.div
                key={style.name}
                variants={fanVariants}
                className="group relative"
                style={{
                  zIndex: i === 1 ? 3 : 1,
                  marginLeft: i === 0 ? 0 : -24,
                  marginRight: i === 2 ? 0 : 0,
                }}
                whileHover={{
                  y: -16,
                  rotate: 0,
                  zIndex: 10,
                  transition: { duration: 0.3, ease: "easeOut" },
                }}
                initial={false}
                animate={{
                  rotate: style.rotation,
                }}
                transition={{ duration: 0.3 }}
              >
                <div
                  className="relative w-[220px] sm:w-[260px] md:w-[300px] overflow-hidden rounded-2xl ring-1 ring-black/8 transition-shadow duration-300 group-hover:shadow-[0_20px_50px_rgba(0,0,0,0.2)]"
                  style={{
                    boxShadow: `0 ${8 + Math.abs(style.rotation)}px ${24 + Math.abs(style.rotation) * 2}px rgba(0,0,0,0.12)`,
                  }}
                >
                  <div className="relative aspect-[3/4]">
                    <Image
                      src={style.image}
                      alt={`${style.name} style storybook illustration`}
                      fill
                      className="object-cover transition-transform duration-500 group-hover:scale-105"
                      sizes="(max-width: 768px) 260px, 300px"
                    />

                    {/* Overlay that reveals on hover (always visible on mobile) */}
                    <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent p-5 opacity-0 transition-opacity duration-300 group-hover:opacity-100 sm:opacity-0 max-sm:opacity-100">
                      <p className="font-serif text-sm leading-snug text-white/90">
                        &ldquo;{style.tagline}&rdquo;
                      </p>
                    </div>
                  </div>
                </div>

                {/* Label below */}
                <p
                  className="mt-4 text-center font-serif text-sm font-semibold"
                  style={{ color: style.accentColor }}
                >
                  {style.name}
                </p>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
