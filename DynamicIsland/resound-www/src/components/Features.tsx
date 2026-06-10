"use client";

import { useScrollReveal } from "@/hooks/useScrollReveal";

const features = [
  {
    title: "Dynamic Island Pill",
    description:
      "A compact notch pill that expands on hover — just like the real thing. Shows album art, track info, and playback progress.",
    shipped: true,
  },
  {
    title: "Waveform Visualization",
    description:
      "Customizable animated waveform that pulses along with your music. Multiple styles and color options.",
    shipped: true,
  },
  {
    title: "Global Hotkeys",
    description:
      "Control playback from anywhere. Assign custom shortcuts for play/pause, skip, previous, and toggling the island.",
    shipped: true,
  },
  {
    title: "Spotify & Apple Music",
    description:
      "Works with both Spotify and Apple Music. Automatically detects the active source and shows now-playing info.",
    shipped: true,
  },
  {
    title: "Menu Bar Controls",
    description:
      "Quick access to track info, playback controls, and settings from the menu bar. No dock icon needed.",
    shipped: true,
  },
  {
    title: "Customizable Position",
    description:
      "Position the pill at the left, center, or right of your notch. Or use it without a notch entirely.",
    shipped: false,
  },
];

export default function Features() {
  const { ref, visible } = useScrollReveal(0.05);

  return (
    <section
      id="features"
      className="relative py-24 md:py-32 px-6 overflow-hidden"
    >
      {/* Decorative corner glow */}
      <div className="absolute -top-40 -right-40 w-[400px] h-[400px] rounded-full bg-emerald-glow blur-[120px] opacity-20 pointer-events-none" />
      <div className="absolute -bottom-40 -left-40 w-[400px] h-[400px] rounded-full bg-emerald-glow blur-[120px] opacity-15 pointer-events-none" />

      <div className="max-w-6xl mx-auto relative z-10">
        <div className="text-center mb-16" ref={ref}>
          <h2
            className={`text-3xl md:text-5xl font-display font-bold tracking-tight transition-all duration-700 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
              visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
            }`}
          >
            Everything you need
          </h2>
          <p
            className={`mt-4 text-text-secondary text-lg max-w-xl mx-auto transition-all duration-700 delay-100 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] ${
              visible ? "opacity-100 translate-y-0" : "opacity-0 translate-y-6"
            }`}
          >
            Built for music lovers who spend all day at their Mac.
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-3">
          {features.map((f, i) => (
            <div
              key={f.title}
              className={`group relative bg-surface-raised hover:bg-surface-hover border border-border rounded-2xl p-8 transition-all duration-500 [transition-timing-function:cubic-bezier(0.23,1,0.32,1)] active:scale-[0.98] ${
                visible
                  ? "opacity-100 translate-y-0"
                  : "opacity-0 translate-y-8"
              }`}
              style={{
                transitionDelay: `${300 + i * 80}ms`,
              }}
            >
              {/* Hover accent line */}
              <div className="absolute inset-x-0 top-0 h-px bg-emerald/0 group-hover:bg-emerald/40 transition-colors duration-300" />

              {!f.shipped && (
                <span className="inline-block px-2.5 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-emerald bg-emerald/10 rounded-full mb-4">
                  Coming soon
                </span>
              )}
              <h3
                className={`font-display font-semibold text-lg mb-2 ${f.shipped ? "" : ""}`}
              >
                {f.title}
              </h3>
              <p className="text-sm text-text-secondary leading-relaxed group-hover:text-text-primary/80 transition-colors duration-300">
                {f.description}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
