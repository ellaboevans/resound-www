"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useScrollReveal } from "@/hooks/useScrollReveal";

const faqs = [
  {
    q: "Is Resound free?",
    a: "Yes, Resound is completely free and open source.",
  },
  {
    q: "Does it work on Macs without a notch?",
    a: "Yes. The pill positions itself at the top center of your screen and works on any Mac, notch or not.",
  },
  {
    q: "Which music services are supported?",
    a: "Spotify and Apple Music. Resound automatically detects which one is playing and shows the current track.",
  },
  {
    q: "Will it drain my battery?",
    a: "Resound is lightweight and optimized. It only polls for track changes, so CPU usage is minimal.",
  },
  {
    q: "Can I customize the hotkeys?",
    a: "Yes. Open Settings from the menu bar icon and assign your preferred keyboard shortcuts.",
  },
  {
    q: "Is there a way to reset the app?",
    a: "Run `defaults delete com.resound.mac` in Terminal, then restart the app.",
  },
];

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);
  const { ref, visible } = useScrollReveal(0.1);

  return (
    <section id="faq" className="relative py-24 md:py-32 px-6 overflow-hidden">
      <div className="absolute -top-40 left-1/2 -translate-x-1/2 w-[500px] h-[300px] rounded-full bg-emerald-glow blur-[120px] opacity-10 pointer-events-none" />

      <div className="max-w-3xl mx-auto relative z-10" ref={ref}>
        <div className="text-center mb-16">
          <h2
            className={`text-3xl md:text-5xl font-display font-bold tracking-tight transition-all duration-700 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
              visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
            }`}
          >
            Frequently asked
          </h2>
          <p
            className={`mt-4 text-text-secondary text-lg transition-all duration-700 delay-100 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
              visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
            }`}
          >
            Everything you need to know.
          </p>
        </div>

        <div className="space-y-2">
          {faqs.map((faq, i) => (
            <div
              key={i}
              className={`border border-border rounded-xl overflow-hidden transition-all duration-500 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
                visible
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 translate-y-6"
              }`}
              style={{ transitionDelay: `${400 + i * 80}ms` }}
            >
              <button
                onClick={() => setOpenIndex(openIndex === i ? null : i)}
                className="w-full flex items-center justify-between px-6 py-4 text-left bg-surface-raised hover:bg-surface-hover transition-colors duration-200"
              >
                <span className="font-display font-semibold text-sm">
                  {faq.q}
                </span>
                <motion.svg
                  animate={{ rotate: openIndex === i ? 45 : 0 }}
                  transition={{ duration: 0.2, ease: [0.23, 1, 0.32, 1] }}
                  className="w-4 h-4 text-text-muted shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M12 4v16m8-8H4"
                  />
                </motion.svg>
              </button>
              <AnimatePresence initial={false}>
                {openIndex === i && (
                  <motion.div
                    key="answer"
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: "auto", opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.25, ease: [0.23, 1, 0.32, 1] }}
                    className="overflow-hidden"
                  >
                    <p className="px-6 pb-4 text-sm text-text-secondary leading-relaxed bg-surface-raised">
                      {faq.a}
                    </p>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
