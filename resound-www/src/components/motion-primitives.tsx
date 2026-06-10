"use client";

import { motion, useReducedMotion } from "framer-motion";
import type { ComponentProps, ReactNode } from "react";

import { cn } from "@/lib/utils";

const ease = [0.32, 0.72, 0, 1] as const;

type RevealProps = ComponentProps<typeof motion.div> & {
  children: ReactNode;
  delay?: number;
};

export function Reveal({ children, className, delay = 0, ...props }: RevealProps) {
  const prefersReducedMotion = useReducedMotion();

  return (
    <motion.div
      className={className}
      initial={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, y: 18 }}
      whileInView={prefersReducedMotion ? { opacity: 1 } : { opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "0px 0px -100px" }}
      transition={{ duration: 0.52, delay, ease }}
      {...props}
    >
      {children}
    </motion.div>
  );
}

export function HeroReveal({ children, className, delay = 0, ...props }: RevealProps) {
  const prefersReducedMotion = useReducedMotion();

  return (
    <motion.div
      className={className}
      initial={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, y: 12 }}
      whileInView={prefersReducedMotion ? { opacity: 1 } : { opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "0px 0px -80px" }}
      transition={{ duration: 0.62, delay, ease }}
      {...props}
    >
      {children}
    </motion.div>
  );
}

export function Lift({
  children,
  className,
  ...props
}: ComponentProps<typeof motion.div> & { children: ReactNode }) {
  const prefersReducedMotion = useReducedMotion();

  return (
    <motion.div
      className={cn("will-change-transform", className)}
      whileHover={prefersReducedMotion ? undefined : { y: -4 }}
      whileTap={prefersReducedMotion ? undefined : { scale: 0.98 }}
      transition={{ duration: 0.24, ease }}
      {...props}
    >
      {children}
    </motion.div>
  );
}

export function StageReveal({ children, className, ...props }: RevealProps) {
  const prefersReducedMotion = useReducedMotion();

  return (
    <motion.div
      className={className}
      initial={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, y: 24, scale: 0.98 }}
      whileInView={prefersReducedMotion ? { opacity: 1 } : { opacity: 1, y: 0, scale: 1 }}
      viewport={{ once: true, margin: "0px 0px -80px" }}
      transition={{ duration: 0.72, delay: 0.12, ease }}
      {...props}
    >
      {children}
    </motion.div>
  );
}
