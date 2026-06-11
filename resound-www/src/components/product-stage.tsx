"use client";

import Image from "next/image";
import { FastForward, Pause, Play } from "lucide-react";
import { useEffect, useState } from "react";

function AudioWave({ isPlaying }: { isPlaying: boolean }) {
  const heights = isPlaying ? [10, 18, 13, 22, 15] : [6, 9, 7, 10, 8];
  const durations = [0.64, 0.86, 0.72, 0.94, 0.78];

  return (
    <div
      className="flex h-6 items-center gap-1 text-[#b7d6c6]"
      aria-hidden="true">
      {heights.map((height, index) => (
        <span
          key={`${height}-${index}`}
          className={`w-1 rounded-full bg-current transition-all duration-300 ${
            isPlaying ? "animate-pulse opacity-90" : "opacity-45"
          }`}
          style={{
            height: `${height}px`,
            animationDuration: isPlaying ? `${durations[index]}s` : "0s",
            animationIterationCount: "infinite",
            animationTimingFunction: "ease-in-out",
          }}
        />
      ))}
    </div>
  );
}

function BrandMark({ className = "size-8" }: Readonly<{ className?: string }>) {
  return (
    <Image
      src="/resound/resound.svg"
      alt=""
      width={64}
      height={64}
      className={className}
      aria-hidden="true"
      priority
    />
  );
}

function AlbumArtwork({
  className = "size-8",
}: Readonly<{ className?: string }>) {
  return (
    <svg
      className={className}
      viewBox="0 0 96 96"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true">
      <rect width="96" height="96" rx="22" fill="#07100C" />
      <rect
        x="1"
        y="1"
        width="94"
        height="94"
        rx="21"
        stroke="#D5E6DC"
        strokeOpacity="0.12"
        strokeWidth="2"
      />
      <path
        d="M17 57C24.5 45.5 31.5 45.5 39 57C46.5 68.5 53.5 68.5 61 57C66.5 48.6 72 46.2 79 49.8"
        stroke="#D7EADF"
        strokeWidth="5"
        strokeLinecap="round"
      />
      <path
        d="M17 39C25 30.6 33 30.6 41 39C49 47.4 57 47.4 65 39C69.7 34.1 74.4 32.2 79 33.3"
        stroke="#86A895"
        strokeOpacity="0.7"
        strokeWidth="4"
        strokeLinecap="round"
      />
      <circle cx="27" cy="25" r="4" fill="#D7EADF" fillOpacity="0.8" />
      <circle cx="72" cy="70" r="3" fill="#D7EADF" fillOpacity="0.42" />
    </svg>
  );
}

function UserAvatar({
  className = "size-8",
}: Readonly<{ className?: string }>) {
  return (
    <svg
      className={className}
      viewBox="0 0 96 96"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden="true">
      <rect width="96" height="96" rx="48" fill="#050806" />
      <rect
        x="2"
        y="2"
        width="92"
        height="92"
        rx="46"
        stroke="#D5E6DC"
        strokeOpacity="0.16"
        strokeWidth="4"
      />
      <circle cx="48" cy="36" r="13" fill="#B7D6C6" fillOpacity="0.9" />
      <path
        d="M24 76C28.2 62.8 37.1 56 48 56C58.9 56 67.8 62.8 72 76"
        fill="#B7D6C6"
        fillOpacity="0.75"
      />
      <path
        d="M26 23C39.1 14.8 56.5 14.4 70 23"
        stroke="#D7EADF"
        strokeOpacity="0.28"
        strokeWidth="4"
        strokeLinecap="round"
      />
    </svg>
  );
}

function formatTime(seconds: number) {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;

  return `${minutes}:${remainingSeconds < 10 ? "0" : ""}${remainingSeconds}`;
}

function getLockScreenClock() {
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

export function ProductStage() {
  const [isPlaying, setIsPlaying] = useState(true);
  const [currentTime, setCurrentTime] = useState(31);
  const [password, setPassword] = useState("");
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [clock, setClock] = useState(getLockScreenClock);

  useEffect(() => {
    const interval = globalThis.setInterval(() => {
      setClock(getLockScreenClock());
    }, 1000);

    return () => globalThis.clearInterval(interval);
  }, []);

  useEffect(() => {
    if (!isPlaying) {
      return;
    }

    const interval = globalThis.setInterval(() => {
      setCurrentTime((previous) => (previous >= 255 ? 0 : previous + 1));
    }, 1000);

    return () => globalThis.clearInterval(interval);
  }, [isPlaying]);

  function handlePasswordSubmit(event: React.SyntheticEvent<HTMLFormElement>) {
    event.preventDefault();

    if (password === "1234" || password.toLowerCase() === "resound") {
      setIsUnlocked(true);

      globalThis.setTimeout(() => {
        setIsUnlocked(false);
        setPassword("");
      }, 2500);

      return;
    }

    const input = document.getElementById("product-stage-password");
    input?.classList.add("animate-bounce");
    globalThis.setTimeout(() => input?.classList.remove("animate-bounce"), 500);
  }

  return (
    <div className="group/stage relative isolate mx-auto w-full overflow-hidden rounded-2xl border border-white/10 bg-[#030504] shadow-2xl shadow-black/80">
      <div className="relative z-20 flex h-12 items-center justify-between border-b border-white/8 bg-[#070b09]/90 px-4 text-[11px] text-white/50 backdrop-blur-xl">
        <div className="flex items-center gap-2" aria-hidden="true">
          <span className="block size-3 rounded-full bg-[#ff5f57] opacity-85 transition-opacity hover:opacity-100" />
          <span className="block size-3 rounded-full bg-[#ffbd2e] opacity-85 transition-opacity hover:opacity-100" />
          <span className="block size-3 rounded-full bg-[#28c840] opacity-85 transition-opacity hover:opacity-100" />
        </div>
        <div className="absolute left-1/2 -translate-x-1/2 text-[10px] font-medium tracking-wide text-white/70 uppercase">
          {isUnlocked ? "Welcome Back" : "Lock Screen Preview"}
        </div>
        <div className="flex items-center gap-3 font-mono text-[10px]">
          <span>Resound</span>
        </div>
      </div>

      <div className="relative aspect-9/16 min-h-150 overflow-hidden transition-all duration-500 sm:aspect-4/3 sm:min-h-162.5 lg:aspect-video lg:min-h-175">
        <div
          className={`absolute inset-0 bg-[linear-gradient(135deg,#07100c_0%,#0f2d1b_22%,#637034_45%,#d2a24d_64%,#1c120d_100%)] bg-size-[180%_180%] transition-transform duration-1000 ${
            isPlaying ? "animate-[pulse_8s_infinite]" : "opacity-80"
          }`}
        />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_48%_22%,rgba(255,255,255,0.18),transparent_35%),radial-gradient(circle_at_66%_74%,rgba(17,24,39,0.85),transparent_45%),linear-gradient(to_bottom,rgba(0,0,0,0.1),rgba(0,0,0,0.8))] mix-blend-multiply" />
        <div className="absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.05)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.05)_1px,transparent_1px)] bg-size-[48px_48px] opacity-10" />

        <div className="relative z-10 flex h-full w-full flex-col items-center justify-between px-4 py-8 sm:px-8 sm:py-12 lg:py-16">
          <div className="w-full text-center">
            <div className="mb-1 text-[10px] font-bold tracking-[0.25em] text-emerald-400 uppercase">
              {clock.date}
            </div>
            <h2 className="select-none text-5xl font-extralight tracking-tight text-white/90 drop-shadow-xl sm:text-6xl lg:text-7xl">
              {clock.time}
            </h2>
          </div>

          <div className="w-full max-w-79.5 rounded-[1.35rem] border border-[#c9e7d7]/12 bg-[#030706]/82 px-3.5 py-3.5 text-white shadow-2xl shadow-black/75 ring-1 ring-black/40 backdrop-blur-2xl transition-all duration-300 hover:scale-[1.01] hover:border-[#c9e7d7]/22 sm:max-w-87 sm:px-4 sm:py-4">
            <div className="mb-3 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="grid size-6 place-items-center">
                  <BrandMark className="size-5.5" />
                </div>
                <span className="text-[9px] font-semibold tracking-[0.18em] text-[#b7d6c6]/70 uppercase">
                  Now Playing
                </span>
              </div>
              <AudioWave isPlaying={isPlaying} />
            </div>

            <div className="flex min-w-0 items-center gap-3">
              <div className="grid size-12 shrink-0 place-items-center overflow-hidden rounded-[0.95rem] border border-[#c9e7d7]/10 bg-[#050806] shadow-lg shadow-black/50 ring-1 ring-white/3 transition-transform duration-300 hover:rotate-2 sm:size-13">
                <AlbumArtwork className="size-full" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold tracking-tight text-[#eef7f2] sm:text-[15px]">
                  Put It On God
                </p>
                <p className="mt-0.5 truncate text-[11px] font-medium text-[#9fbdaf]">
                  AlorG & Sarkodie
                </p>
              </div>
            </div>

            <div className="mt-3.5">
              <div className="group relative h-1 cursor-pointer overflow-hidden rounded-full bg-[#d5e6dc]/12">
                <div
                  className="absolute top-0 left-0 h-full rounded-full bg-[#d7eadf]"
                  style={{ width: `${(currentTime / 255) * 100}%` }}
                />
              </div>
              <div className="mt-2 flex justify-between font-mono text-[10px] text-[#b7d6c6]/48">
                <span>{formatTime(currentTime)}</span>
                <span>-{formatTime(255 - currentTime)}</span>
              </div>
            </div>

            <div className="mt-2.5 flex items-center justify-center gap-6 text-[#c9e7d7]/60">
              <button
                type="button"
                onClick={() =>
                  setCurrentTime((previous) => Math.max(0, previous - 15))
                }
                className="grid size-8 place-items-center rounded-full text-[#c9e7d7]/58 transition-all hover:bg-[#d5e6dc]/8 hover:text-[#eef7f2] active:scale-90"
                title="Previous">
                <FastForward
                  className="size-4 fill-current -rotate-180"
                  strokeWidth={0}
                  aria-hidden="true"
                />
              </button>

              <button
                type="button"
                onClick={() => setIsPlaying((playing) => !playing)}
                className="grid size-10 place-items-center rounded-full border border-[#d5e6dc]/20 bg-[#d7eadf] text-[#03100a] shadow-lg shadow-black/40 transition-all hover:bg-white active:scale-90 sm:size-11"
                title={isPlaying ? "Pause" : "Play"}>
                {isPlaying ? (
                  <Pause
                    className="size-4.5 fill-current"
                    strokeWidth={2}
                    aria-hidden="true"
                  />
                ) : (
                  <Play
                    className="size-4.5 translate-x-px fill-current"
                    strokeWidth={2}
                    aria-hidden="true"
                  />
                )}
              </button>

              <button
                type="button"
                onClick={() =>
                  setCurrentTime((previous) => Math.min(255, previous + 15))
                }
                className="grid size-8 place-items-center rounded-full text-[#c9e7d7]/58 transition-all hover:bg-[#d5e6dc]/8 hover:text-[#eef7f2] active:scale-90"
                title="Next">
                <FastForward
                  className="size-4 fill-current"
                  strokeWidth={0}
                  aria-hidden="true"
                />
              </button>
            </div>
          </div>

          <form
            onSubmit={handlePasswordSubmit}
            className="relative flex w-full max-w-65 flex-col items-center gap-3 pt-6">
            {isUnlocked ? (
              <div className="absolute inset-x-0 -top-8 rounded-xl border border-emerald-500/20 bg-emerald-500/10 py-2 text-center text-xs font-semibold text-emerald-400 shadow-lg backdrop-blur-md">
                Unlocked successfully
              </div>
            ) : null}

            <div className="grid size-11 place-items-center rounded-full border border-white/10 bg-[#050806]/80 p-2 shadow-xl ring-1 ring-white/5 backdrop-blur-xl transition-all duration-300 hover:border-emerald-500/30 hover:ring-emerald-500/20">
              <UserAvatar className="size-full" />
            </div>

            <div className="text-center">
              <p className="text-xs font-bold tracking-tight text-white">
                Small God Studio
              </p>
            </div>

            <div className="relative w-full">
              <input
                id="product-stage-password"
                type="password"
                placeholder={
                  isUnlocked ? "Access Granted" : "Enter Password (resound)"
                }
                value={password}
                disabled={isUnlocked}
                onChange={(event) => setPassword(event.target.value)}
                className="h-8 w-full rounded-lg border border-white/10 bg-black/60 px-3.5 pr-8 text-center text-xs font-medium text-white shadow-inner backdrop-blur-xl transition-all placeholder:text-white/30 focus:border-emerald-500/50 focus:ring-1 focus:ring-emerald-500/40 focus:outline-none"
              />
              <button
                type="submit"
                className="absolute top-1/2 right-2 -translate-y-1/2 p-1 text-white/40 transition-all hover:text-white">
                <svg
                  className="size-4"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2.5}
                  aria-hidden="true">
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M13.5 4.5L21 12m0 0l-7.5 7.5M21 12H3"
                  />
                </svg>
              </button>
            </div>

            <p className="text-[9px] font-medium tracking-[0.15em] text-white/40 uppercase">
              Press Enter or submit to unlock
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}
