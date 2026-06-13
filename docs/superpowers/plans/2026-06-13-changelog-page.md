# Changelog Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/changelog` page to the Resound landing site with release notes, plus a footer link.

**Architecture:** Single TypeScript data file, one new route page, one footer link. No API endpoints, no build-time generation, no external deps.

**Tech Stack:** Next.js App Router, Tailwind CSS, `@/components/ui/badge`, same motion primitives as existing pages.

---

### Task 1: Create changelog data file

**Files:**
- Create: `resound-www/src/content/changelog.ts`

- [ ] **Step 1: Create the data file**

```ts
export interface ChangelogEntry {
  version: string;
  date: string;
  type: "feature" | "fix" | "improvement";
  description: string;
  isBeta: boolean;
}

export const changelog: ChangelogEntry[] = [
  {
    version: "0.1.0",
    date: "2026-06-13",
    type: "feature",
    description: "Windows & Linux desktop builds released.",
    isBeta: true,
  },
  {
    version: "0.1.0",
    date: "2026-06-13",
    type: "fix",
    description: "Fixed Windows progress bar freeze on screen lock/unlock.",
    isBeta: true,
  },
  {
    version: "0.1.0",
    date: "2026-06-12",
    type: "feature",
    description: "Resound Desktop beta: Tauri v2 + Vue 3 cross-platform companion with floating pill UI, system tray, Now Playing sync via GSMTC (Windows) and MPRIS (Linux).",
    isBeta: true,
  },
  {
    version: "1.0.0",
    date: "2026-06-09",
    type: "feature",
    description: "macOS Dynamic Island companion app with NowPlaying, MediaRemote, browser tab detection, and multi-monitor support.",
    isBeta: false,
  },
];
```

- [ ] **Step 2: Commit**

```bash
git add resound-www/src/content/changelog.ts
git commit -m "feat: add changelog data file with initial entries"
```

---

### Task 2: Create changelog page

**Files:**
- Create: `resound-www/src/app/changelog/page.tsx`

- [ ] **Step 1: Create the page**

```tsx
"use client";

import { HeroReveal, Reveal } from "@/components/motion-primitives";
import { Badge } from "@/components/ui/badge";
import { changelog } from "@/content/changelog";
import { cn } from "@/lib/utils";

const typeStyles: Record<string, string> = {
  feature: "bg-emerald-500/10 text-emerald-500 border-emerald-500/20",
  fix: "bg-amber-500/10 text-amber-500 border-amber-500/20",
  improvement: "bg-blue-500/10 text-blue-500 border-blue-500/20",
};

const typeLabels: Record<string, string> = {
  feature: "Feature",
  fix: "Fix",
  improvement: "Improvement",
};

function DashedGridBackground() {
  return (
    <div
      aria-hidden="true"
      className="pointer-events-none absolute inset-0 z-0 opacity-12"
      style={{
        backgroundImage: `
          linear-gradient(to right, #e7e5e4 1px, transparent 1px),
          linear-gradient(to bottom, #e7e5e4 1px, transparent 1px)
        `,
        backgroundPosition: "0 0, 0 0",
        backgroundSize: "20px 20px",
        maskComposite: "intersect",
        maskImage: `
          repeating-linear-gradient(to right, black 0px, black 3px, transparent 3px, transparent 8px),
          repeating-linear-gradient(to bottom, black 0px, black 3px, transparent 3px, transparent 8px)
        `,
        WebkitMaskComposite: "source-in",
        WebkitMaskImage: `
          repeating-linear-gradient(to right, black 0px, black 3px, transparent 3px, transparent 8px),
          repeating-linear-gradient(to bottom, black 0px, black 3px, transparent 3px, transparent 8px)
        `,
      }}
    />
  );
}

export default function ChangelogPage() {
  return (
    <main className="relative isolate min-h-screen overflow-x-clip">
      <DashedGridBackground />
      <div className="relative z-10">
        <section className="mx-auto w-[min(760px,calc(100%-2.5rem))] pt-42 pb-20 sm:pt-48 sm:pb-24">
          <HeroReveal>
            <h1 className="font-heading text-5xl leading-[1.1] font-black tracking-normal sm:text-6xl">
              Changelog
            </h1>
          </HeroReveal>
          <HeroReveal delay={0.05}>
            <p className="mt-4 max-w-xl text-lg leading-8 text-muted-foreground">
              What's new in Resound.
            </p>
          </HeroReveal>

          <div className="mt-14 space-y-2">
            {changelog.map((entry, index) => (
              <Reveal key={index} delay={index * 0.03}>
                <div className="flex items-start gap-4 rounded-lg border border-border/60 bg-card/30 px-5 py-4">
                  <Badge
                    className={cn(
                      "mt-0.5 shrink-0 font-mono text-[11px] font-bold tracking-tight uppercase",
                      entry.isBeta
                        ? "border-amber-500/30 bg-amber-500/10 text-amber-500"
                        : "border-emerald-500/30 bg-emerald-500/10 text-emerald-500",
                    )}>
                    {entry.isBeta ? "Beta" : "Stable"}
                    <span className="text-current/60">v{entry.version}</span>
                  </Badge>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-3">
                      <span className={cn(
                        "inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] font-semibold tracking-wide uppercase",
                        typeStyles[entry.type],
                      )}>
                        {typeLabels[entry.type]}
                      </span>
                      <time className="text-xs text-muted-foreground/60">
                        {entry.date}
                      </time>
                    </div>
                    <p className="mt-2 text-sm leading-6 text-muted-foreground">
                      {entry.description}
                    </p>
                  </div>
                </div>
              </Reveal>
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add resound-www/src/app/changelog/page.tsx
git commit -m "feat: add changelog page"
```

---

### Task 3: Add footer link

**Files:**
- Modify: `resound-www/src/components/site-footer.tsx:4-8`

- [ ] **Step 1: Add Changelog to footer links**

```ts
const footerLinks = [
  { label: "Features", href: "/#features" },
  { label: "Changelog", href: "/changelog" },
  { label: "Download", href: "/download" },
  { label: "@dev_concept", href: "https://x.com/dev_concept" },
];
```

- [ ] **Step 2: Commit**

```bash
git add resound-www/src/components/site-footer.tsx
git commit -m "feat: add changelog link to footer"
```

---

### Task 4: Final verification

- [ ] **Step 1: TypeScript check**

Run: `cd resound-www && npx tsc --noEmit`

Expected: No type errors.

- [ ] **Step 2: Build check**

Run: `cd resound-www && npm run build`

Expected: Build succeeds.

- [ ] **Step 3: Push**

```bash
git push
```
