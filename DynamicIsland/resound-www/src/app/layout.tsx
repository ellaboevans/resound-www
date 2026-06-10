import type { Metadata } from "next";
import { Bricolage_Grotesque, Sora } from "next/font/google";
import "./globals.css";

const display = Bricolage_Grotesque({
  variable: "--font-display",
  subsets: ["latin"],
});

const body = Sora({
  variable: "--font-body",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Resound — Dynamic Island Music Controller for macOS",
  description:
    "A macOS menubar app that brings Dynamic Island-style music controls to your Mac. Works with Spotify and Apple Music.",
  icons: { icon: "/logo.svg" },
  openGraph: {
    title: "Resound — Dynamic Island for macOS",
    description:
      "A macOS menubar app that brings Dynamic Island-style music controls to your Mac.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${display.variable} ${body.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
