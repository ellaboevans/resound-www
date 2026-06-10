"use client";

import { useState } from "react";
import { useScrollReveal } from "@/hooks/useScrollReveal";

const steps = [
  {
    num: "01",
    title: "Download the DMG",
    desc: "Grab the latest Resound.dmg from the releases page.",
  },
  {
    num: "02",
    title: "Drag to Applications",
    desc: "Open the DMG and drag Resound.app into your Applications folder.",
  },
];

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);

  return (
    <button
      onClick={() => {
        navigator.clipboard.writeText(text);
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      }}
      className="absolute top-2 right-2 w-7 h-7 flex items-center justify-center rounded-md bg-surface-raised border border-border text-text-muted hover:text-text-primary hover:border-text-muted transition-all duration-200 active:scale-90"
      aria-label="Copy command"
    >
      {copied ? (
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="text-emerald">
          <polyline points="20 6 9 17 4 12" />
        </svg>
      ) : (
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
          <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" />
        </svg>
      )}
    </button>
  );
}

export default function Install() {
  const { ref, visible } = useScrollReveal(0.1);

  return (
    <section
      id="install"
      className="relative py-24 md:py-32 px-6 overflow-hidden"
    >
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] rounded-full bg-emerald-glow blur-[140px] opacity-10 pointer-events-none" />

      <div className="max-w-5xl mx-auto relative z-10" ref={ref}>
        <div className="text-center mb-16">
          <h2
            className={`text-3xl md:text-5xl font-display font-bold tracking-tight transition-all duration-700 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
              visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
            }`}
          >
            Get started
          </h2>
          <p
            className={`mt-4 text-text-secondary text-lg transition-all duration-700 delay-100 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
              visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
            }`}
          >
            Download, drag, and done.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {steps.slice(0, 2).map((step, i) => (
            <div
              key={i}
              className={`flex flex-col p-6 bg-surface border border-border rounded-xl transition-all duration-700 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
                visible
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 translate-y-6"
              } group hover:border-emerald/20 hover:bg-surface-raised`}
              style={{ transitionDelay: `${300 + i * 150}ms` }}
            >
              <span className="w-9 h-9 rounded-lg bg-emerald/10 border border-emerald/20 flex items-center justify-center text-xs font-bold text-emerald font-mono mb-4">
                {step.num}
              </span>
              <h3 className="font-display font-semibold text-lg text-text-primary">
                {step.title}
              </h3>
              <p className="mt-2 text-text-secondary text-sm leading-relaxed">
                {step.desc}
              </p>
              {step.code && (
                <pre className="mt-4 p-3 bg-surface border border-border rounded-lg overflow-x-auto text-xs group-hover:border-emerald/20 transition-colors duration-300">
                  <code className="font-mono text-emerald-light break-all">
                    {step.code}
                  </code>
                </pre>
              )}
            </div>
          ))}
        </div>

        {/* Step 03 — full width */}
        <div
          className={`mt-6 flex flex-col p-6 bg-surface border border-border rounded-xl transition-all duration-700 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
            visible
              ? "opacity-100 translate-y-0"
              : "opacity-0 translate-y-6"
          } group hover:border-emerald/20 hover:bg-surface-raised`}
          style={{ transitionDelay: `${300 + 2 * 150}ms` }}
        >
          <span className="w-9 h-9 rounded-lg bg-emerald/10 border border-emerald/20 flex items-center justify-center text-xs font-bold text-emerald font-mono mb-4">
            03
          </span>
          <h3 className="font-display font-semibold text-lg text-text-primary">
            Bypass Gatekeeper
          </h3>
          <p className="mt-2 text-text-secondary text-sm leading-relaxed">
            If macOS warns about an unidentified developer, run this in Terminal:
          </p>
          <div className="relative mt-4 group/code">
            <pre className="p-3 bg-surface border border-border rounded-lg overflow-x-auto text-xs transition-colors duration-300 group-hover/code:border-emerald/20">
              <code className="font-mono text-emerald-light break-all">
                sudo xattr -r -d com.apple.quarantine /Applications/Resound.app
              </code>
            </pre>
            <CopyButton text="sudo xattr -r -d com.apple.quarantine /Applications/Resound.app" />
          </div>
        </div>
      </div>
    </section>
  );
}
