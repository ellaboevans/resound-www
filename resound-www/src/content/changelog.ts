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
    description: "Fixed Windows expanded panel clipping on high-DPI displays (physical vs logical pixel mismatch).",
    isBeta: true,
  },
  {
    version: "0.1.0",
    date: "2026-06-13",
    type: "fix",
    description: "Fixed mobile download page horizontal overflow on accordion expand.",
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
    description:
      "Resound Desktop beta: Tauri v2 + Vue 3 cross-platform companion with floating pill UI, system tray, Now Playing sync via GSMTC (Windows) and MPRIS (Linux).",
    isBeta: true,
  },
  {
    version: "1.0.0",
    date: "2026-06-09",
    type: "feature",
    description:
      "macOS Dynamic Island companion app with NowPlaying, MediaRemote, browser tab detection, and multi-monitor support.",
    isBeta: false,
  },
];
