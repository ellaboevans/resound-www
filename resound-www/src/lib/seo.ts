export const siteUrl = (
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://useresound.elabo.me"
).replace(/\/$/, "");

export const siteConfig = {
  name: "Resound",
  title: "Resound - Dynamic Island Music Controller for Mac",
  description:
    "A Dynamic Island-style music controller for macOS with artwork, waveforms, playback controls, hotkeys, and menu bar access.",
  url: siteUrl,
  ogImage: "/opengraph-image.png",
  creator: "Evans Elabo",
  keywords: [
    "Resound",
    "Dynamic Island for Mac",
    "macOS music controller",
    "Mac menu bar music app",
    "Spotify Mac controller",
    "Apple Music Mac controller",
    "now playing Mac",
    "macOS Sonoma",
  ],
} as const;

export function absoluteUrl(path = "/") {
  if (path.startsWith("http")) {
    return path;
  }

  return `${siteConfig.url}${path.startsWith("/") ? path : `/${path}`}`;
}
