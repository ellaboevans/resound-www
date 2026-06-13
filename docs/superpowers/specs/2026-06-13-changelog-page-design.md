# Changelog Page

## Overview

A `/changelog` page on the Resound landing site that shows release notes chronologically, so users can track what's changed across versions.

## Data

Single TypeScript file at `resound-www/src/content/changelog.ts`.

```ts
export interface ChangelogEntry {
  version: string;
  date: string;
  type: "feature" | "fix" | "improvement";
  description: string;
  isBeta: boolean;
}
```

Entries are ordered newest-first. The file is manually maintained — entries are added by editing the array.

## Page (`/changelog`)

- New route: `resound-www/src/app/changelog/page.tsx`
- Same dark aesthetic as the rest of the site (DashedGridBackground, HeroReveal section)
- List renders all entries in order with no pagination or filtering
- Each entry row shows:
  - **Version badge** — small chip with the version string; color depends on `isBeta`
    - `isBeta: true` → amber/warm tones
    - `isBeta: false` → green/emerald tones
  - **Date** — right-aligned or secondary position
  - **Type tag** — subtle label (`feature`, `fix`, `improvement`)
  - **Description** — plain text or light markdown

## Navigation

- Footer on all pages gets a new "Changelog" link alongside existing platform links
- Points to `/changelog`

## Implementation Order

1. Create `resound-www/src/content/changelog.ts` with initial entries (seeded from this session's release history)
2. Create `resound-www/src/app/changelog/page.tsx` with the list layout
3. Add footer link
