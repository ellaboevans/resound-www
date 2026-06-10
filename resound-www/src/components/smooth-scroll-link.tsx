"use client";

import Link from "next/link";
import type { ComponentProps } from "react";

type SmoothScrollLinkProps = ComponentProps<typeof Link>;

export function SmoothScrollLink({
  href,
  onClick,
  ...props
}: SmoothScrollLinkProps) {
  return (
    <Link
      href={href}
      onClick={(event) => {
        onClick?.(event);

        if (event.defaultPrevented || typeof href !== "string" || !href.startsWith("#")) {
          return;
        }

        const target = document.querySelector(href);
        if (!target) {
          return;
        }

        event.preventDefault();
        target.scrollIntoView({ behavior: "smooth", block: "start" });
        window.history.pushState(null, "", href);
      }}
      {...props}
    />
  );
}
