import Image from "next/image";
import Link from "next/link";
import {
  ArrowDownToLine,
  BadgeCheck,
  CircleDot,
  Keyboard,
  Menu,
  Music2,
  PanelTop,
  SlidersHorizontal,
  Waves,
} from "lucide-react";

import { FaqSection } from "@/components/faq-section";
import {
  HeroReveal,
  Lift,
  Reveal,
  StageReveal,
} from "@/components/motion-primitives";
import { SmoothScrollLink } from "@/components/smooth-scroll-link";
import { Badge } from "@/components/ui/badge";
import { buttonVariants } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { absoluteUrl, siteConfig } from "@/lib/seo";
import { cn } from "@/lib/utils";

const features = [
  {
    icon: PanelTop,
    title: "Dynamic Island pill",
    copy: "Collapsed now-playing state expands on hover into transport controls and track details.",
  },
  {
    icon: Music2,
    title: "Spotify and Music",
    copy: "Reads playback state from Spotify and Apple Music using native macOS scripting hooks.",
  },
  {
    icon: CircleDot,
    title: "Artwork and progress",
    copy: "Shows album art, elapsed time, remaining time, and an at-a-glance progress bar.",
  },
  {
    icon: Waves,
    title: "Waveform styles",
    copy: "Compact visualizers make the pill feel alive without taking over the screen.",
  },
  {
    icon: Keyboard,
    title: "Global hotkeys",
    copy: "Bind play, pause, next, previous, and island toggle shortcuts from the settings panel.",
  },
  {
    icon: Menu,
    title: "Native menubar",
    copy: "Quick controls live in a real macOS status menu with settings and quit always available.",
  },
];

const installSteps = [
  {
    title: "Open the DMG",
    copy: "Launch the downloaded installer and drag Resound into Applications.",
  },
  {
    title: "Start Resound",
    copy: "The app runs as a menubar utility and does not keep a dock icon around.",
  },
  {
    title: "Allow the app",
    copy: "If macOS blocks launch, remove the quarantine attribute from the installed app.",
  },
];

const faqs = [
  {
    question: "Does it require a notch?",
    answer:
      "No. The island can still sit at the top of the screen on Macs without a notch.",
  },
  {
    question: "Which music apps work?",
    answer:
      "Spotify and Apple Music are supported by the current app integration. YouTube Music is also supported through Chrome.",
  },
  {
    question: "Which screen does the island show on?",
    answer:
      "You can choose between showing on all connected displays or a single screen. Open Resound's settings and pick from the display dropdown. Useful if you only want it on your external monitor or built-in display.",
  },
  {
    question: "How do I get YouTube Music to work in Chrome?",
    answer:
      "Resound needs a one-time Chrome setting: open DevTools with Cmd+Opt+I, then go to View \u2192 Developer \u2192 Allow JavaScript from Apple Events and click to enable it. Resound will show a dialog with these steps when you first open YouTube Music.",
  },
  {
    question: "Why does Resound ask to access Google Chrome?",
    answer:
      "Resound uses Chrome to detect YouTube Music tabs, read the current track, and send playback controls. When enabled, Chrome will show a system prompt \u2014 approve it so Resound can scan your tabs. If JavaScript execution is blocked, Resound will show a one-time dialog with setup instructions.",
  },
  {
    question: "Does it show in the dock?",
    answer:
      "No. The release app is configured as a menubar utility with no dock icon.",
  },
  {
    question: "Can I change the position?",
    answer:
      "Yes. Settings include left, center, and right placement plus adjustable notch width.",
  },
];

const footerColumns = [
  {
    title: "Product",
    links: [
      { label: "Features", href: "#features" },
      { label: "Install", href: "#install" },
      { label: "FAQ", href: "#faq" },
      { label: "Download DMG", href: "/resound/Resound.dmg", download: true },
    ],
  },
  {
    title: "Resources",
    links: [
      { label: "Requirements", href: "#install" },
      { label: "Setup notes", href: "#install" },
      { label: "Questions", href: "#faq" },
    ],
  },
  {
    title: "Support",
    links: [
      { label: "Installation help", href: "#install" },
      { label: "macOS Sonoma+", href: "#install" },
      { label: "Spotify & Apple Music", href: "#features" },
    ],
  },
];

const socialLinks = [
  {
    label: "Download",
    href: "/resound/Resound.dmg",
    icon: ArrowDownToLine,
    download: true,
  },
  {
    label: "FAQ",
    href: "#faq",
    icon: BadgeCheck,
  },
];

const structuredData = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "WebSite",
      "@id": absoluteUrl("/#website"),
      name: siteConfig.name,
      url: absoluteUrl("/"),
      description: siteConfig.description,
      inLanguage: "en-US",
      publisher: {
        "@id": absoluteUrl("/#person"),
      },
    },
    {
      "@type": "Person",
      "@id": absoluteUrl("/#person"),
      name: siteConfig.creator,
    },
    {
      "@type": "SoftwareApplication",
      "@id": absoluteUrl("/#software"),
      name: siteConfig.name,
      applicationCategory: "MultimediaApplication",
      operatingSystem: "macOS Sonoma or later",
      url: absoluteUrl("/"),
      image: absoluteUrl(siteConfig.ogImage),
      description: siteConfig.description,
      downloadUrl: absoluteUrl("/resound/Resound.dmg"),
      author: {
        "@id": absoluteUrl("/#person"),
      },
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
      },
    },
  ],
};

export default function Home() {
  return (
    <main className="relative isolate min-h-screen overflow-hidden">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
      />
      <DashedGridBackground />
      <div className="relative z-10">
        <Header />
        <Hero />
        <Features />
        <Install />
        <Faq />
        <Footer />
      </div>
    </main>
  );
}

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
          repeating-linear-gradient(
            to right,
            black 0px,
            black 3px,
            transparent 3px,
            transparent 8px
          ),
          repeating-linear-gradient(
            to bottom,
            black 0px,
            black 3px,
            transparent 3px,
            transparent 8px
          )
        `,
        WebkitMaskComposite: "source-in",
        WebkitMaskImage: `
          repeating-linear-gradient(
            to right,
            black 0px,
            black 3px,
            transparent 3px,
            transparent 8px
          ),
          repeating-linear-gradient(
            to bottom,
            black 0px,
            black 3px,
            transparent 3px,
            transparent 8px
          )
        `,
      }}
    />
  );
}

function Header() {
  return (
    <header className="fixed inset-x-0 top-0 z-20 border-b bg-background/80 backdrop-blur-xl">
      <div className="mx-auto flex h-16 w-[min(1160px,calc(100%-2.5rem))] items-center justify-between gap-5">
        <SmoothScrollLink
          href="#top"
          className="flex items-center gap-2.5 font-heading text-xl font-black">
          <span className="grid size-9 place-items-center overflow-hidden rounded-lg border bg-card">
            <Image
              src="/resound/resound.svg"
              alt=""
              width={36}
              height={36}
              priority
            />
          </span>
          <p>Resound</p>
        </SmoothScrollLink>

        <nav className="flex items-center gap-5 text-sm font-semibold text-muted-foreground">
          <SmoothScrollLink
            className="hidden transition-colors hover:text-foreground sm:inline"
            href="#features">
            Features
          </SmoothScrollLink>
          <SmoothScrollLink
            className="hidden transition-colors hover:text-foreground sm:inline"
            href="#install">
            Install
          </SmoothScrollLink>
          <SmoothScrollLink
            className="hidden transition-colors hover:text-foreground md:inline"
            href="#faq">
            FAQ
          </SmoothScrollLink>
          <Link
            className={cn(buttonVariants({ size: "lg" }), "h-10")}
            href="/resound/Resound.dmg"
            download>
            <ArrowDownToLine data-icon="inline-start" />
            Download
          </Link>
        </nav>
      </div>
    </header>
  );
}

function Hero() {
  return (
    <section
      id="top"
      className="mx-auto flex min-h-dvh w-[min(1160px,calc(100%-2.5rem))] flex-col items-center justify-end pt-56 pb-16">
      <div className="flex w-full flex-col items-center gap-12">
        <div className="mx-auto flex flex-col items-center text-center">
          <HeroReveal>
            <h1 className="mt-5 text-balance font-heading text-6xl leading-[0.9] font-black tracking-normal sm:text-7xl lg:text-8xl xl:text-[8.2rem]">
              Your music, tucked into the notch.
            </h1>
          </HeroReveal>

          <HeroReveal delay={0.06}>
            <p className="mt-7 max-w-2xl text-lg leading-8 text-muted-foreground sm:text-xl">
              Resound brings a Dynamic Island-style now-playing controller to
              Mac: artwork, waveform motion, playback controls, hotkeys, and a
              quiet menubar presence.
            </p>
          </HeroReveal>

          <HeroReveal delay={0.12}>
            <div className="mt-9 flex flex-wrap justify-center gap-3">
              <Link
                className={cn(
                  buttonVariants({ size: "lg" }),
                  "h-12 px-5 text-base font-bold",
                )}
                href="/resound/Resound.dmg"
                download>
                <ArrowDownToLine data-icon="inline-start" />
                Download Resound
              </Link>
              <SmoothScrollLink
                className={cn(
                  buttonVariants({ variant: "outline", size: "lg" }),
                  "h-12 px-5 text-base",
                )}
                href="#features">
                <PanelTop data-icon="inline-start" />
                Explore features
              </SmoothScrollLink>
            </div>
          </HeroReveal>

          <HeroReveal delay={0.16}>
            <p className="mt-5 text-sm text-muted-foreground">
              Requires macOS Sonoma or later. Works with Spotify and Apple
              Music.
            </p>
          </HeroReveal>
        </div>

        <StageReveal className="w-full">
          <ProductStage />
        </StageReveal>
      </div>
    </section>
  );
}

function ProductStage() {
  return (
    <div className="relative min-h-97.5 w-full max-w-5xl overflow-hidden rounded-lg border bg-card shadow-2xl shadow-black/40 sm:min-h-[470px] lg:min-h-[560px]">
      <div className="flex h-10 items-center justify-between border-b bg-secondary/35 px-4 text-[11px] text-muted-foreground">
        <div className="flex items-center gap-2" aria-hidden="true">
          <span className="size-3 rounded-full bg-[#ff5f57]" />
          <span className="size-3 rounded-full bg-[#ffbd2e]" />
          <span className="size-3 rounded-full bg-[#28c840]" />
        </div>
        <div className="absolute left-1/2 -translate-x-1/2 font-medium text-foreground/70">
          Resound Preview
        </div>
        <div className="flex items-center gap-3">
          <span className="hidden sm:inline">Wi-Fi</span>
          <span className="hidden sm:inline">Sound</span>
          <span>Resound</span>
        </div>
      </div>

      <div className="absolute top-10 left-1/2 flex h-12 w-[min(72%,386px)] -translate-x-1/2 items-center justify-between rounded-b-2xl border border-t-0 bg-black px-3.5 shadow-2xl shadow-black/60">
        <span className="size-6 rounded-md border bg-primary" />
        <span className="flex h-7 items-center gap-1">
          <span className="h-3 w-1 rounded-full bg-foreground/75 animate-wave-a" />
          <span className="h-6 w-1 rounded-full bg-foreground/75 animate-wave-b" />
          <span className="h-4 w-1 rounded-full bg-foreground/75 animate-wave-c" />
          <span className="h-7 w-1 rounded-full bg-foreground/75 animate-wave-a" />
          <span className="h-3.5 w-1 rounded-full bg-foreground/75 animate-wave-b" />
        </span>
      </div>
    </div>
  );
}

function Features() {
  return (
    <section id="features" className=" py-20 sm:py-24">
      <div className="mx-auto w-[min(1160px,calc(100%-2.5rem))]">
        <SectionHead
          title="A small app with a sharp job."
          copy="Resound stays out of the dock and gives music controls a dedicated place at the top of the screen, close to where your attention already lands."
        />

        <div className="grid gap-px overflow-hidden rounded-lg border bg-border sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, index) => (
            <Lift key={feature.title} className="h-full">
              <Card className="h-full rounded-none border-0 ring-0">
                <CardHeader>
                  <div className="mb-7 grid size-11 place-items-center rounded-md border bg-primary/5 text-primary">
                    <feature.icon />
                  </div>
                  <Badge variant="secondary" className="mb-3 w-fit">
                    {String(index + 1).padStart(2, "0")}
                  </Badge>
                  <CardTitle className="text-3xl font-black leading-none">
                    {feature.title}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <CardDescription className="text-[0.95rem] leading-6">
                    {feature.copy}
                  </CardDescription>
                </CardContent>
              </Card>
            </Lift>
          ))}
        </div>
      </div>
    </section>
  );
}

function Install() {
  return (
    <section id="install" className=" py-20 sm:py-24">
      <div className="mx-auto w-[min(1160px,calc(100%-2.5rem))]">
        <SectionHead
          title="Install in a minute."
          copy="Download the DMG, move the app to Applications, and clear quarantine if macOS flags the unsigned build."
        />

        <div className="grid min-w-0 gap-7">
          <div className="grid min-w-0 grid-cols-1 gap-3 md:grid-cols-3">
            {installSteps.map((step, index) => (
              <Reveal key={step.title} className="min-w-0" delay={index * 0.04}>
                <Lift className="h-full min-w-0">
                  <Card className="h-full min-w-0">
                    <CardHeader className="min-w-0">
                      <Badge className="mb-2 w-fit">
                        {String(index + 1).padStart(2, "0")}
                      </Badge>
                      <CardTitle className="text-2xl leading-none font-black">
                        {step.title}
                      </CardTitle>
                      <CardDescription className="leading-6">
                        {step.copy}
                      </CardDescription>
                    </CardHeader>
                  </Card>
                </Lift>
              </Reveal>
            ))}
          </div>

          <Reveal className="min-w-0">
            <Card className="min-w-0 bg-black/70">
              <CardHeader>
                <CardTitle className="flex min-w-0 items-center gap-2 text-xl font-black">
                  <SlidersHorizontal />
                  Terminal fallback
                </CardTitle>
                <CardDescription>
                  Use this only if macOS blocks the local unsigned app build.
                </CardDescription>
              </CardHeader>
              <CardContent>
                <pre className="max-w-full overflow-x-auto rounded-md border bg-background/70 p-4 font-mono text-xs leading-6 text-primary sm:p-5 sm:text-sm sm:leading-7">
                  <code>
                    {`sudo xattr -r -d com.apple.quarantine /Applications/Resound.app

# Then open Resound from Applications`}
                  </code>
                </pre>
              </CardContent>
            </Card>
          </Reveal>
        </div>
      </div>
    </section>
  );
}

function Faq() {
  return (
    <section id="faq" className=" py-20 sm:py-24">
      <div className="mx-auto w-[min(1160px,calc(100%-2.5rem))]">
        <SectionHead
          title="Questions before it lives in your menu bar."
          copy="Resound is intentionally narrow: a fast Mac utility for music presence and control."
        />

        <FaqSection items={faqs} />
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="pt-20 pb-9 text-sm text-muted-foreground">
      <div className="mx-auto w-[min(1160px,calc(100%-2.5rem))]">
        <div className="grid gap-10 rounded-lg border bg-card/80 p-6 shadow-2xl shadow-black/20 md:grid-cols-[1.25fr_1.75fr] lg:p-8">
          <div className="flex max-w-md flex-col gap-6">
            <SmoothScrollLink
              href="#top"
              className="flex w-fit items-center gap-3 font-heading text-2xl font-black text-foreground">
              <span className="grid size-11 place-items-center overflow-hidden rounded-lg border bg-background">
                <Image
                  src="/resound/resound.svg"
                  alt=""
                  width={44}
                  height={44}
                />
              </span>
              Resound
            </SmoothScrollLink>

            <p className="max-w-sm leading-7">
              A quiet macOS music controller that keeps playback close to your
              notch, menu bar, and keyboard.
            </p>

            <div className="flex flex-wrap gap-3">
              <Link
                className={cn(buttonVariants({ size: "lg" }), "h-11")}
                href="/resound/Resound.dmg"
                download>
                <ArrowDownToLine data-icon="inline-start" />
                Download
              </Link>
              <SmoothScrollLink
                className={cn(
                  buttonVariants({ variant: "outline", size: "lg" }),
                  "h-11",
                )}
                href="#features">
                <PanelTop data-icon="inline-start" />
                Features
              </SmoothScrollLink>
            </div>
          </div>

          <div className="grid gap-8 sm:grid-cols-3">
            {footerColumns.map((column) => (
              <div key={column.title} className="flex flex-col gap-4">
                <h3 className="font-heading text-base font-black text-foreground">
                  {column.title}
                </h3>
                <ul className="flex flex-col gap-3">
                  {column.links.map((item) => (
                    <li key={item.label}>
                      {item.href.startsWith("#") ? (
                        <SmoothScrollLink
                          href={item.href}
                          className="inline-flex items-center gap-1.5 transition-colors hover:text-foreground">
                          {item.label}
                        </SmoothScrollLink>
                      ) : (
                        <Link
                          href={item.href}
                          download={item.download}
                          className="inline-flex items-center gap-1.5 transition-colors hover:text-foreground">
                          {item.label}
                        </Link>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>

        <Separator className="my-6" />

        <div className="flex flex-col gap-5 md:flex-row md:items-center md:justify-between">
          <div className="flex flex-wrap items-center gap-3">
            <span className="inline-flex items-center gap-2">
              <BadgeCheck className="text-primary" />
              Built by Evans Elabo.
            </span>
            <span className="hidden text-border sm:inline">/</span>
            <span>Resound for macOS Sonoma and later.</span>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {socialLinks.map((item) =>
              item.href.startsWith("#") ? (
                <SmoothScrollLink
                  key={item.label}
                  href={item.href}
                  aria-label={item.label}
                  className="inline-flex size-10 items-center justify-center rounded-md border bg-card text-muted-foreground transition-colors hover:text-foreground">
                  <item.icon />
                </SmoothScrollLink>
              ) : (
                <Link
                  key={item.label}
                  href={item.href}
                  download={item.download}
                  aria-label={item.label}
                  className="inline-flex size-10 items-center justify-center rounded-md border bg-card text-muted-foreground transition-colors hover:text-foreground">
                  <item.icon />
                </Link>
              ),
            )}
          </div>
        </div>
      </div>
    </footer>
  );
}

function SectionHead({
  title,
  copy,
}: Readonly<{ title: string; copy: string }>) {
  return (
    <div className="mb-9 flex items-center flex-col justify-center gap-6 text-center">
      <h2 className="text-balance font-heading text-5xl leading-[0.95] font-black tracking-normal sm:text-6xl lg:text-7xl">
        {title}
      </h2>
      <p className="max-w-xl text-lg leading-8 text-muted-foreground lg:justify-self-start">
        {copy}
      </p>
    </div>
  );
}
