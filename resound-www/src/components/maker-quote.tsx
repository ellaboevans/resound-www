"use client";

import { motion, useReducedMotion } from "framer-motion";

export function MakerQuote() {
  const prefersReducedMotion = useReducedMotion();

  const blur = (px: number) =>
    prefersReducedMotion
      ? { opacity: 0 }
      : { opacity: 0.3, filter: `blur(${px}px)` };

  const clear = prefersReducedMotion
    ? { opacity: 1 }
    : { opacity: 1, filter: "blur(0px)" };

  return (
    <section className="py-20 sm:py-24">
      <p className="text-center uppercase tracking-[0.3em] mb-12 text-primary underline decoration-dashed decoration-primary/30 decoration-2 underline-offset-4 font-medium">
        Made In Ghana
      </p>
      <div className="mx-auto flex w-[min(800px,calc(100%-2.5rem))] flex-col items-center text-center">
        <motion.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: false, margin: "-100px 0px" }}
          variants={{
            visible: {
              transition: { staggerChildren: 0.3, delayChildren: 0.08 },
            },
          }}>
          <div className="relative">
            <motion.span
              variants={{ hidden: blur(6), visible: clear }}
              transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
              aria-hidden="true"
              className="absolute -left-1 -top-7 font-heading text-8xl leading-none text-primary/75 select-none sm:-left-3 sm:-top-10 sm:text-9xl">
              &ldquo;
            </motion.span>
            <motion.p
              variants={{ hidden: blur(6), visible: clear }}
              transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
              className="font-heading text-4xl leading-[1.05] font-black tracking-tight text-foreground sm:text-5xl lg:text-6xl">
              I built something I wanted for myself.
            </motion.p>
          </div>

          <motion.p
            variants={{ hidden: blur(6), visible: clear }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="font-heading text-4xl leading-[1.15] font-black tracking-tight text-foreground sm:text-5xl lg:text-6xl">
            I kept seeing tools like this and thinking: why pay for it when I
            can plan it, study how it works, and build my own?{" "}
            <span className="text-muted-foreground">So I did.</span>
          </motion.p>

          <motion.div
            variants={{ hidden: blur(4), visible: clear }}
            transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
            className="mt-10">
            <cite className="block  text-base">
              <span className="font-semibold text-foreground">Evans&#x2c;</span>
              <span className="text-muted-foreground ml-1">
                creator of Resound
              </span>
            </cite>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
