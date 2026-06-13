import Image from "next/image";
import Link from "next/link";
import { ArrowDownToLine, Megaphone } from "lucide-react";

import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function SiteHeader() {
  const announcements = [
    "Lock-screen controls are coming soon.",
    "Richer shortcuts are on the roadmap.",
    "More music sources are planned.",
  ];

  return (
    <>
      <aside className="fixed inset-x-0 top-0 z-30 overflow-hidden border-b border-primary/20 bg-[radial-gradient(circle_at_18%_20%,rgba(184,241,196,0.2),transparent_28%),linear-gradient(90deg,#06100b,#0d1d13_48%,#07100c)] text-foreground shadow-lg shadow-black/20 backdrop-blur-xl">
        <div className="mx-auto flex h-10 w-[min(1160px,calc(100%-2.5rem))] items-center justify-center gap-2 text-center text-xs font-semibold sm:text-sm">
          <Megaphone className="size-3.5 shrink-0 text-primary" />

          <div className="flex min-w-0 items-center gap-1.5 sm:hidden">
            <span className="shrink-0 text-muted-foreground">Coming soon:</span>
            <div className="h-5 min-w-0 overflow-hidden">
              <div className="animate-announcement-carousel flex flex-col">
                {announcements.map((announcement) => (
                  <span
                    key={announcement}
                    className="h-5 shrink-0 truncate leading-5 text-foreground">
                    {announcement}
                  </span>
                ))}
              </div>
            </div>
          </div>

          <div className="hidden min-w-0 items-center gap-1.5 sm:flex">
            <span className="truncate text-muted-foreground">Coming soon:</span>
            <span className="truncate text-foreground">
              lock-screen controls, richer shortcuts, and more music sources.
            </span>
          </div>
        </div>
      </aside>

      <header className="fixed inset-x-0 top-10 z-20 border-b bg-background/80 backdrop-blur-xl">
        <div className="mx-auto flex h-16 w-[min(1160px,calc(100%-2.5rem))] items-center justify-between gap-5">
          <Link
            href="/"
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
          </Link>

          <nav className="flex items-center gap-5 text-sm font-semibold text-muted-foreground">
            <Link
              className="hidden transition-colors hover:text-foreground sm:inline"
              href="/#features">
              Features
            </Link>
            <Link
              className="hidden transition-colors hover:text-foreground sm:inline"
              href="/#install">
              Install
            </Link>
            <Link
              className="hidden transition-colors hover:text-foreground md:inline"
              href="/#faq">
              FAQ
            </Link>
            <Link
              className={cn(buttonVariants({ size: "lg" }), "h-10")}
              href="/download">
              <ArrowDownToLine data-icon="inline-start" />
              Download
            </Link>
          </nav>
        </div>
      </header>
    </>
  );
}
