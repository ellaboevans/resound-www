import Image from "next/image";
import Link from "next/link";

const footerLinks = [
  { label: "Features", href: "/#features" },
  { label: "Changelog", href: "/changelog" },
  { label: "Download", href: "/download" },
  { label: "@dev_concept", href: "https://x.com/dev_concept" },
];

export function SiteFooter() {
  const date = new Date().getFullYear();
  return (
    <footer className="relative z-10 border-t border-border/60 bg-background py-9 text-sm text-muted-foreground">
      <div className="mx-auto flex w-[min(1160px,calc(100%-2.5rem))] flex-col gap-7 md:flex-row md:items-center md:justify-between">
        <Link
          href="/"
          className="flex w-fit items-center gap-3 font-heading text-lg font-black text-foreground">
          <Image
            src="/resound/resound.svg"
            alt=""
            width={22}
            height={22}
            className="size-5 rounded-sm border bg-card"
          />
          Resound
        </Link>

        <nav
          aria-label="Footer"
          className="flex flex-wrap items-center gap-x-6 gap-y-3 font-semibold">
          {footerLinks.map((item) => (
            <Link
              key={item.label}
              href={item.href}
              className="transition-colors hover:text-foreground">
              {item.label}
            </Link>
          ))}
        </nav>

        <p className="text-muted-foreground/80">
          Built by Evans. © {date} Resound.
        </p>
      </div>
    </footer>
  );
}
