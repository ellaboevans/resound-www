"use client";

import { useEffect, useState, useRef } from "react";
import { motion, useSpring } from "framer-motion";

export default function Hero() {
  const [mounted, setMounted] = useState(false);
  const pillRef = useRef<HTMLDivElement>(null);

  const mouseX = useSpring(0, { stiffness: 80, damping: 15 });
  const mouseY = useSpring(0, { stiffness: 80, damping: 15 });

  useEffect(() => {
    setMounted(true);

    const handleMouse = (e: MouseEvent) => {
      const cx = window.innerWidth / 2;
      const cy = window.innerHeight / 2;
      mouseX.set((e.clientX - cx) / cx);
      mouseY.set((e.clientY - cy) / cy);
    };

    window.addEventListener("mousemove", handleMouse);
    return () => window.removeEventListener("mousemove", handleMouse);
  }, [mouseX, mouseY]);

  const containerVariants = {
    hidden: {},
    visible: {
      transition: { staggerChildren: 0.12 },
    },
  };

  const childVariants = {
    hidden: { opacity: 0, y: 30 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.7, ease: [0.23, 1, 0.32, 1] as [number, number, number, number] },
    },
  };

  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center overflow-hidden px-6">
      {/* Ambient glow layers */}
      <div className="absolute top-1/3 left-1/2 -translate-x-1/2 w-[700px] h-[400px] rounded-full bg-emerald-glow blur-[140px] animate-glow pointer-events-none" />
      <div className="absolute top-1/4 -left-32 w-[300px] h-[300px] rounded-full bg-emerald-glow blur-[100px] opacity-20 pointer-events-none" />
      <div className="absolute bottom-1/4 -right-32 w-[300px] h-[300px] rounded-full bg-emerald-glow blur-[100px] opacity-15 pointer-events-none" />

      {/* Pill mockup with mouse tracking */}
      <motion.div
        ref={pillRef}
        variants={containerVariants}
        initial="hidden"
        animate={mounted ? "visible" : "hidden"}
        className="relative z-10 mb-14"
        style={{
          transformStyle: "preserve-3d",
          perspective: "800px",
        }}
      >
        <motion.div
          className="animate-float"
          style={{
            rotateX: mouseY as any,
            rotateY: mouseX as any,
          }}
        >
          <svg
            width="300"
            height="48"
            viewBox="0 0 300 48"
            className="drop-shadow-2xl"
          >
            <defs>
              <linearGradient id="pill-bg" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#1A1A1A" />
                <stop offset="100%" stopColor="#0D0D0D" />
              </linearGradient>
            </defs>
            <rect
              x="2"
              y="2"
              width="296"
              height="44"
              rx="22"
              fill="url(#pill-bg)"
              stroke="#252525"
              strokeWidth="1"
            />
            {/* Notch cutout */}
            <rect x="130" y="0" width="40" height="8" rx="4" fill="#080808" />
            {/* Avatar */}
            <rect x="10" y="10" width="28" height="28" rx="6" fill="#0D5E3C" />
            <rect x="14" y="14" width="20" height="20" rx="3" fill="#1A8A5A" opacity={0.5} />
            {/* Waveform */}
            {[4, 7, 5, 10, 6, 9, 4, 8, 5].map((h, i) => (
              <rect
                key={i}
                x={44 + i * 7}
                y={30 - h}
                width="3.5"
                height={h}
                rx="1.75"
                fill="#1A8A5A"
                opacity={0.3 + h * 0.07}
              />
            ))}
            {/* Track info */}
            <text x="112" y="21" fill="#FAFAFA" fontSize="10" fontFamily="system-ui" fontWeight="600">
              Midnight City
            </text>
            <text x="112" y="34" fill="#888" fontSize="9" fontFamily="system-ui">
              M83 &bull; Hurry Up, We&apos;re Dreaming
            </text>
            {/* Progress bar */}
            <rect x="230" y="20" width="58" height="3" rx="1.5" fill="#1A1A1A" />
            <rect x="230" y="20" width="32" height="3" rx="1.5" fill="#0D5E3C" />
            {/* Volume dot */}
            <circle cx="246" cy="33" r="3" fill="#555" />
            <circle cx="258" cy="33" r="3" fill="#0D5E3C" />
            <circle cx="270" cy="33" r="3" fill="#555" />
          </svg>
        </motion.div>
      </motion.div>

      {/* Heading */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate={mounted ? "visible" : "hidden"}
        className="relative z-10 text-center max-w-4xl"
      >
        <motion.h1 variants={childVariants} className="text-5xl md:text-7xl font-display font-bold tracking-tight leading-[1.1]">
          <span className="text-text-primary">Your Mac deserves</span>
          <br />
          <span className="text-emerald">a Dynamic Island</span>
        </motion.h1>

        <motion.p
          variants={childVariants}
          className="mt-6 text-lg md:text-xl text-text-secondary max-w-xl mx-auto leading-relaxed"
        >
          A sleek menubar controller for Spotify and Apple Music.
          Compact when idle, expansive when you need it.
        </motion.p>

        <motion.div
          variants={childVariants}
          className="mt-10 flex flex-col sm:flex-row justify-center gap-4"
        >
          <a
            href="#install"
            className="group relative px-8 py-3.5 bg-emerald hover:bg-emerald-light text-white rounded-xl font-body font-semibold text-sm transition-all duration-200 active:scale-[0.97]"
          >
            Download Resound
          </a>
          <a
            href="#features"
            className="px-8 py-3.5 border border-border hover:border-text-muted text-text-secondary hover:text-text-primary rounded-xl font-body text-sm transition-all duration-200 active:scale-[0.97]"
          >
            See features
          </a>
        </motion.div>
      </motion.div>

      {/* Scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={mounted ? { opacity: 1 } : {}}
        transition={{ delay: 1.5, duration: 0.6 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2"
      >
        <div className="w-5 h-8 border-2 border-border rounded-full flex justify-center pt-2">
          <div className="w-1 h-2 bg-text-muted rounded-full animate-bounce" />
        </div>
      </motion.div>
    </section>
  );
}
