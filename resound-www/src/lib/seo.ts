export const siteUrl = (
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://useresound.elabo.me"
).replace(/\/$/, "");

export const siteConfig = {
  name: "Resound",
  title: "Resound - Dynamic Island Music Controller",
  description:
    "A Dynamic Island-style music controller for macOS, Windows, and Linux with artwork, waveforms, and playback controls.",
  url: siteUrl,
  ogImage: "/opengraph-image.png",
  creator: "Evans Elabo",
  keywords: [
    "Resound",
    "Dynamic Island for desktop",
    "music controller",
    "menu bar music app",
    "Spotify controller",
    "Apple Music controller",
    "now playing",
    "cross-platform music app",
  ],
} as const;

export function absoluteUrl(path = "/") {
  if (path.startsWith("http")) {
    return path;
  }

  return `${siteConfig.url}${path.startsWith("/") ? path : `/${path}`}`;
}
