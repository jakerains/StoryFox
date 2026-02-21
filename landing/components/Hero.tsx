"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import {
  fadeUpVariants,
  scaleInVariants,
  staggerContainer,
} from "@/lib/motion";
import { DownloadButton } from "./DownloadButton";

export function Hero() {
  return (
    <section className="paper-texture relative overflow-hidden pt-20 pb-12 sm:min-h-screen sm:pt-24 sm:pb-16">
      {/* Ambient glow effects */}
      <div className="glow-amber pointer-events-none absolute -right-32 -top-32 h-[300px] w-[300px] sm:h-[500px] sm:w-[500px]" />
      <div className="glow-peach pointer-events-none absolute -bottom-24 -left-24 h-[250px] w-[250px] sm:h-[400px] sm:w-[400px]" />
      <div className="pointer-events-none absolute left-1/2 top-32 h-[350px] w-[350px] sm:h-[600px] sm:w-[600px] -translate-x-1/2 rounded-full bg-[var(--sj-highlight)]/10 blur-[120px]" />

      <motion.div
        className="mx-auto flex max-w-4xl flex-col items-center px-4 text-center sm:px-6 lg:px-8"
        variants={staggerContainer}
        initial="hidden"
        animate="visible"
      >
        {/* Hero illustration with floating accents */}
        <motion.div variants={scaleInVariants} className="relative -mb-2">
          <Image
            src="/images/storyfox-hero.png"
            alt="StoryFox — a fox curled up with a storybook"
            width={560}
            height={560}
            priority
            className="w-[320px] sm:w-[460px] md:w-[600px] lg:w-[720px] h-auto drop-shadow-[0_16px_48px_rgba(180,84,58,0.25)]"
          />

          {/* Floating sparkles around the illustration — pure SVG, no orbs */}
          {[
            { pos: "-left-10 bottom-20", size: 20, color: "var(--sj-gold)", delay: 0, dur: 5, rotate: true },
            { pos: "-right-8 top-14", size: 16, color: "var(--sj-coral)", delay: 1.5, dur: 4.5, rotate: false },
            { pos: "-right-12 bottom-28", size: 14, color: "var(--sj-highlight)", delay: 0.8, dur: 5.5, rotate: true },
            { pos: "-left-14 top-24", size: 12, color: "var(--sj-gold)", delay: 2, dur: 6, rotate: false },
            { pos: "left-10 -top-2", size: 10, color: "var(--sj-coral)", delay: 0.5, dur: 5, rotate: true },
            { pos: "right-14 top-4", size: 18, color: "var(--sj-gold)", delay: 3, dur: 4, rotate: false },
            { pos: "-left-4 top-1/2", size: 11, color: "var(--sj-highlight)", delay: 1, dur: 7, rotate: true },
            { pos: "right-4 bottom-12", size: 13, color: "var(--sj-gold)", delay: 2.5, dur: 5.2, rotate: false },
          ].map((s, i) => (
            <motion.div
              key={i}
              className={`pointer-events-none absolute ${s.pos}`}
              animate={{
                y: [-6, 6, -6],
                opacity: [0.4, 0.9, 0.4],
                ...(s.rotate ? { rotate: [0, 180, 360] } : {}),
              }}
              transition={{
                duration: s.dur,
                repeat: Infinity,
                ease: "easeInOut",
                delay: s.delay,
              }}
            >
              {/* 4-point sparkle star */}
              <svg width={s.size} height={s.size} viewBox="0 0 24 24" fill={s.color}>
                <path d="M12 0C12.5 7 17 11.5 24 12C17 12.5 12.5 17 12 24C11.5 17 7 12.5 0 12C7 11.5 11.5 7 12 0Z" />
              </svg>
            </motion.div>
          ))}
        </motion.div>

        {/* Background twinkling sparkles scattered across the section (hidden on mobile for performance) */}
        <div className="pointer-events-none hidden sm:block absolute inset-0">
          {[
            { top: "8%", left: "12%", size: 10, delay: 0, dur: 3, color: "var(--sj-gold)" },
            { top: "15%", right: "18%", size: 8, delay: 1.2, dur: 2.5, color: "var(--sj-coral)" },
            { top: "35%", left: "8%", size: 12, delay: 0.6, dur: 3.5, color: "var(--sj-highlight)" },
            { top: "25%", right: "10%", size: 7, delay: 2, dur: 2.8, color: "var(--sj-gold)" },
            { top: "55%", left: "5%", size: 9, delay: 1.8, dur: 3.2, color: "var(--sj-coral)" },
            { top: "45%", right: "7%", size: 8, delay: 0.3, dur: 2.6, color: "var(--sj-gold)" },
            { top: "65%", left: "15%", size: 7, delay: 2.5, dur: 3, color: "var(--sj-highlight)" },
            { top: "70%", right: "14%", size: 10, delay: 0.9, dur: 2.4, color: "var(--sj-gold)" },
            { top: "20%", left: "22%", size: 6, delay: 1.5, dur: 3.8, color: "var(--sj-coral)" },
            { top: "50%", right: "22%", size: 6, delay: 0.4, dur: 3.3, color: "var(--sj-gold)" },
            { top: "80%", left: "10%", size: 8, delay: 2.2, dur: 2.7, color: "var(--sj-highlight)" },
            { top: "40%", right: "4%", size: 6, delay: 1, dur: 3.6, color: "var(--sj-gold)" },
          ].map((dot, i) => (
            <motion.div
              key={`bg-${i}`}
              className="pointer-events-none absolute"
              style={{ top: dot.top, left: dot.left, right: dot.right }}
              animate={{ opacity: [0.1, 0.5, 0.1], scale: [0.8, 1.3, 0.8], rotate: [0, 90, 0] }}
              transition={{
                duration: dot.dur,
                repeat: Infinity,
                ease: "easeInOut",
                delay: dot.delay,
              }}
            >
              <svg width={dot.size} height={dot.size} viewBox="0 0 24 24" fill={dot.color}>
                <path d="M12 0C12.5 7 17 11.5 24 12C17 12.5 12.5 17 12 24C11.5 17 7 12.5 0 12C7 11.5 11.5 7 12 0Z" />
              </svg>
            </motion.div>
          ))}
        </div>

        {/* Tagline */}
        <motion.p
          variants={fadeUpVariants}
          className="mb-3 font-serif text-xl leading-relaxed text-sj-text sm:text-2xl"
        >
          AI-powered illustrated children&apos;s storybooks, on your device.
        </motion.p>

        {/* Description */}
        <motion.p
          variants={fadeUpVariants}
          className="mb-6 max-w-lg text-base leading-relaxed text-sj-secondary sm:text-lg"
        >
          Type a story idea, pick a style, and get a fully illustrated book
          with text, cover art, and print-ready PDF export.
        </motion.p>

        {/* CTA */}
        <motion.div variants={fadeUpVariants}>
          <DownloadButton />
        </motion.div>

        {/* Requirement badges */}
        <motion.div
          variants={fadeUpVariants}
          className="mt-3 flex flex-wrap items-center justify-center gap-2"
        >
          {["macOS 26", "Apple Silicon", "Apple Intelligence"].map((req) => (
            <span
              key={req}
              className="rounded-full border border-sj-border/60 bg-[var(--sj-card)]/60 px-3 py-1 font-sans text-xs font-medium text-sj-muted"
            >
              {req}
            </span>
          ))}
        </motion.div>
      </motion.div>
    </section>
  );
}
