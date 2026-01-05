import { AArrowUp, AArrowDown } from "lucide-react";

export interface FolioTiptapStyledParagraphVariant {
  variant: string;
  title:
    | string
    | {
        cs: string;
        en: string;
      };
  icon?: React.FC<React.SVGProps<SVGSVGElement>>;
}

export const DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_VARIANTS: FolioTiptapStyledParagraphVariant[] =
  [
    {
      variant: "large",
      title: {
        cs: "Velký text",
        en: "Large text",
      },
      icon: AArrowUp,
    },
    {
      variant: "small",
      title: {
        cs: "Malý text",
        en: "Small text",
      },
      icon: AArrowDown,
    },
  ];
