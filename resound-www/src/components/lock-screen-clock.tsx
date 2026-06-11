"use client";

import { useEffect, useState } from "react";

function getLockScreenTime() {
  const now = new Date();

  return {
    time: now.toLocaleTimeString("en-US", {
      hour: "numeric",
      minute: "2-digit",
      hour12: false,
    }),
    date: now.toLocaleDateString("en-US", {
      weekday: "long",
      month: "long",
      day: "numeric",
    }),
  };
}

export function LockScreenClock() {
  const [clock, setClock] = useState(getLockScreenTime);

  useEffect(() => {
    const interval = globalThis.setInterval(() => {
      setClock(getLockScreenTime());
    }, 1000);

    return () => globalThis.clearInterval(interval);
  }, []);

  return (
    <div className="absolute top-[8%] left-[40.5%] lg:left-1/2 z-20 -translate-x-1/2 text-center">
      <p className="font-heading text-5xl leading-none font-light tracking-normal text-white/90 drop-shadow-lg sm:text-8xl lg:text-[7.5rem]">
        {clock.time}
      </p>
      <p className="mt-2 text-[9px] font-bold tracking-[0.18em] text-white/72 uppercase sm:mt-3 sm:text-xs sm:tracking-[0.22em]">
        {clock.date}
      </p>
    </div>
  );
}
