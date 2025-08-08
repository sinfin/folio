import Paragraph from "@tiptap/extension-paragraph";

import {
  FolioTiptapStyledParagraphVariant,
  DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_VARIANTS,
} from "./default-folio-tiptap-styled-paragraph-variants";

export interface StyledParagraphOptions {
  variants: FolioTiptapStyledParagraphVariant[];
}

export const FolioTiptapStyledParagraph = Paragraph.extend<StyledParagraphOptions>({
  name: "folioTiptapStyledParagraph",

  renderHTML({ HTMLAttributes }: { HTMLAttributes: Record<string, any> }) {
    return ["p", { ...HTMLAttributes, class: "f-tiptap-styled-paragraph" }, 0];
  },

  addOptions() {
    return {
      variants: DEFAULT_FOLIO_TIPTAP_STYLED_PARAGRAPH_VARIANTS,
    };
  },

  addAttributes() {
    return {
      variant: {
        default: null,
        parseHTML: (element: HTMLElement) =>
          element.getAttribute("data-variant"),
        renderHTML: (attributes: { variant: string }) => ({
          "data-variant": attributes.variant,
        }),
      },
    };
  },
});
