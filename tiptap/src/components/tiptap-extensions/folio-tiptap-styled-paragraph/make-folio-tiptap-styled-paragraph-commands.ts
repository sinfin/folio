import { TypeOutline } from "lucide-react";
import { type Range, type Editor } from "@tiptap/core";

import { type CommandItem } from "@/components/tiptap-ui/commands/commands-list";
import { normalizeString } from "@/components/tiptap-ui/commands/suggestion"

import type { FolioTiptapStyledParagraphVariant } from './default-folio-tiptap-styled-paragraph-variants';

export const DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_ICON = TypeOutline

export const makeFolioTiptapStyledParagraphCommands = (styledParagraphVariants: FolioTiptapStyledParagraphVariant[]) => {
  return styledParagraphVariants.map((variant) => {
    let title

    if (typeof variant.title === "string") {
      title = { cs: variant.title, en: variant.title }
    } else {
      title = variant.title
    }

    return {
      title,
      icon: variant.icon || DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_ICON,
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor
          .chain()
          .focus()
          .deleteRange(range)
          .setNode("styledParagraph", { variant: variant.variant })
          .run();
      },
    };
  })
};

export default makeFolioTiptapStyledParagraphCommands;
