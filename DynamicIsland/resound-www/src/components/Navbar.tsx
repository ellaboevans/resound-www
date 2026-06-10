"use client";

import { useEffect, useState } from "react";
import { motion, useScroll, useMotionValueEvent } from "framer-motion";

const links = [
  { label: "Features", href: "#features" },
  { label: "Install", href: "#install" },
  { label: "FAQ", href: "#faq" },
];

export default function Navbar() {
  const [mounted, setMounted] = useState(false);
  const [hidden, setHidden] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const { scrollY } = useScroll();

  useEffect(() => setMounted(true), []);

  useMotionValueEvent(scrollY, "change", (latest) => {
    const prev = scrollY.getPrevious();
    if (prev !== undefined && latest > prev && latest > 80) {
      setHidden(true);
    } else {
      setHidden(false);
    }
  });

  return (
    <motion.nav
      initial={{ y: -20, opacity: 0 }}
      animate={
        mounted
          ? {
              y: hidden ? -100 : 0,
              opacity: 1,
            }
          : {}
      }
      transition={{ duration: 0.35, ease: [0.23, 1, 0.32, 1] }}
      className="fixed top-0 left-0 right-0 z-50"
    >
      {/* Backdrop with glass */}
      <div className="absolute inset-0 bg-surface/70 backdrop-blur-xl border-b border-border/50" />

      <div className="relative max-w-6xl mx-auto flex items-center justify-between px-6 py-4">
        {/* Logo */}
        <a href="#" className="flex items-center gap-3 shrink-0">
          <img src="/logo.svg" alt="Resound" className="w-7 h-7" />
          <span className="font-display font-semibold text-sm text-text-primary hidden sm:block">
            Resound
          </span>
        </a>

        {/* Desktop links */}
        <div className="hidden md:flex items-center gap-8">
          {links.map((link) => (
            <a
              key={link.href}
              href={link.href}
              className="text-sm text-text-secondary hover:text-text-primary transition-colors duration-200"
            >
              {link.label}
            </a>
          ))}
        </div>

        {/* Desktop CTA */}
        <a
          href="#install"
          className="hidden md:inline-flex px-5 py-2 bg-emerald hover:bg-emerald-light text-white rounded-lg text-sm font-semibold transition-all duration-200 active:scale-[0.97]"
        >
          Download
        </a>

        {/* Mobile hamburger */}
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="md:hidden relative w-6 h-6 flex flex-col items-center justify-center gap-1"
          aria-label="Menu"
        >
          <motion.span
            animate={menuOpen ? { rotate: 45, y: 4 } : { rotate: 0, y: 0 }}
            className="block w-5 h-px bg-text-secondary"
          />
          <motion.span
            animate={menuOpen ? { opacity: 0 } : { opacity: 1 }}
            className="block w-5 h-px bg-text-secondary"
          />
          <motion.span
            animate={menuOpen ? { rotate: -45, y: -4 } : { rotate: 0, y: 0 }}
            className="block w-5 h-px bg-text-secondary"
          />
        </button>
      </div>

      {/* Mobile menu */}
      <motion.div
        initial={false}
        animate={{
          height: menuOpen ? "auto" : 0,
          opacity: menuOpen ? 1 : 0,
        }}
        transition={{ duration: 0.3, ease: [0.23, 1, 0.32, 1] }}
        className="md:hidden overflow-hidden bg-surface/90 backdrop-blur-xl border-b border-border/50"
      >
        <div className="px-6 pb-5 flex flex-col gap-4">
          {links.map((link) => (
            <a
              key={link.href}
              href={link.href}
              onClick={() => setMenuOpen(false)}
              className="text-sm text-text-muted hover:text-text-secondary transition-colors"
            >
              {link.label}
            </a>
          ))}
          <a
            href="#install"
            onClick={() => setMenuOpen(false)}
            className="inline-flex self-start px-5 py-2 bg-emerald hover:bg-emerald-light text-white rounded-lg text-sm font-semibold transition-all duration-200 active:scale-[0.97]"
          >
            Download
          </a>
        </div>
      </motion.div>
    </motion.nav>
  );
}
