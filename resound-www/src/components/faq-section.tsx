import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from "@/components/ui/accordion";
import { Reveal } from "@/components/motion-primitives";

type FaqItem = {
  question: string;
  answer: string;
};

type FaqSectionProps = {
  items: FaqItem[];
};

export function FaqSection({ items }: FaqSectionProps) {
  return (
    <Accordion className="mx-auto flex w-full max-w-3xl flex-col gap-3">
      {items.map((item, index) => (
        <Reveal key={item.question} delay={index * 0.04}>
          <AccordionItem
            value={`faq-${index}`}
            className="rounded-lg border bg-card px-5 shadow-sm shadow-black/10"
          >
            <AccordionTrigger className="py-5 font-heading text-xl font-black hover:no-underline">
              {item.question}
            </AccordionTrigger>
            <AccordionContent className="pb-5 leading-7 text-muted-foreground">
              {item.answer}
            </AccordionContent>
          </AccordionItem>
        </Reveal>
      ))}
    </Accordion>
  );
}
