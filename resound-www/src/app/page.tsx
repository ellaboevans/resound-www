import Link from "next/link";
import {
  ArrowDownToLine,
  CircleDot,
  Keyboard,
  Menu,
  Music2,
  PanelTop,
  SlidersHorizontal,
} from "lucide-react";

import { FaqSection } from "@/components/faq-section";
import {
  HeroReveal,
  Lift,
  Reveal,
  StageReveal,
} from "@/components/motion-primitives";
import { MakerQuote } from "@/components/maker-quote";
import { ProductStage } from "@/components/product-stage";
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
    icon: CircleDot,
    title: "Progress glance",
    copy: "A compact progress state keeps the current track readable without crowding the notch.",
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
      "Spotify and Apple Music are supported through native integrations. YouTube Music is also supported through Chrome.",
  },
  {
    question: "Where does the player appear on screen?",
    answer:
      "On macOS it sits near the notch area as a Dynamic Island-style pill. On Windows and Linux it appears as a floating pill at the top of the screen that you can drag anywhere.",
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
    question: "Does it show in the dock or taskbar?",
    answer:
      "No. Resound runs quietly with no dock icon on macOS and no taskbar entry on Windows and Linux. It stays out of your way while showing your music.",
  },
  {
    question: "Can I change where it sits?",
    answer:
      "On macOS you can pick left, center, or right placement and adjust how it aligns with the notch. On Windows and Linux the pill is fully draggable — just click and drag it anywhere along the top of the screen.",
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
      operatingSystem: "macOS, Windows, Linux",
      url: absoluteUrl("/"),
      image: absoluteUrl(siteConfig.ogImage),
      description: siteConfig.description,
      downloadUrl: absoluteUrl("/download"),
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
    <main className="relative isolate min-h-screen overflow-x-clip overflow-y-visible">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
      />
      <DashedGridBackground />
      <div className="relative z-10">
        <Hero />
        <Features />
        <Install />
        <MakerQuote />
        <Faq />
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

function Hero() {
  return (
    <section
      id="top"
      className="mx-auto flex min-h-dvh w-[min(1320px,calc(100%-1.5rem))] flex-col items-center justify-end pt-38 pb-12 sm:w-[min(1320px,calc(100%-2.5rem))] sm:pt-42 sm:pb-16">
      <div className="flex w-full flex-col items-center gap-8">
        <div className="mx-auto flex flex-col items-center text-center">
          <HeroReveal>
            <h1 className="mt-5 text-balance font-heading text-6xl leading-[0.9] font-black tracking-normal sm:text-7xl lg:text-8xl xl:text-[8.2rem]">
              Your music, always visible.
            </h1>
          </HeroReveal>

          <HeroReveal delay={0.06}>
            <p className="mt-7 max-w-2xl text-lg leading-8 text-muted-foreground sm:text-xl">
              Resound brings a Dynamic Island-style now-playing controller to
              your desktop: artwork, waveform motion, playback controls,
              hotkeys, and a quiet presence at the top of the screen.
            </p>
          </HeroReveal>

          <HeroReveal delay={0.12}>
            <div className="mt-9 flex flex-wrap justify-center gap-3">
              <Link
                className={cn(
                  buttonVariants({ size: "lg" }),
                  "h-12 px-5 text-base font-bold w-full sm:w-auto",
                )}
                href="/download">
                <ArrowDownToLine data-icon="inline-start" />
                Download Resound
              </Link>
              <SmoothScrollLink
                className={cn(
                  buttonVariants({ variant: "outline", size: "lg" }),
                  "h-12 px-5 text-base w-full sm:w-auto",
                )}
                href="#features">
                <PanelTop data-icon="inline-start" />
                Explore features
              </SmoothScrollLink>
            </div>
          </HeroReveal>

          <HeroReveal delay={0.16}>
            <p className="mt-5 text-sm text-muted-foreground">
              Available on macOS, Windows, and Linux. Works with Spotify and
              Apple Music.
            </p>
          </HeroReveal>
        </div>

        <StageReveal className="relative z-0 w-full max-w-none">
          <ProductStage />
        </StageReveal>
      </div>
    </section>
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
