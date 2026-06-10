import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Resound - Dynamic Island for Mac Music",
  description:
    "A Dynamic Island-style music controller for macOS with now-playing info, waveform visuals, hotkeys, and native menu bar controls.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className="dark h-full antialiased"
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
