import Paragraph from "@tiptap/extension-paragraph";

export interface StyledParagraphOptions {
  variantCommands: FolioEditorCommand[];
}

export const FolioTiptapStyledParagraph = Paragraph.extend<StyledParagraphOptions>({
  name: "folioTiptapStyledParagraph",

  parseHTML() {
    return [
      {
        tag: 'p.f-tiptap-styled-paragraph',
        getAttrs: (element) => {
          if (typeof element === 'string') return false;
          return {
            variant: element.getAttribute('data-f-tiptap-styled-paragraph-variant') || null,
          };
        },
      },
    ];
  },

  renderHTML({ HTMLAttributes }: { HTMLAttributes: Record<string, unknown> }) {
    return ["p", { ...HTMLAttributes, class: "f-tiptap-styled-paragraph" }, 0];
  },

  addOptions() {
    return {
      variantCommands: [],
    };
  },

  addAttributes() {
    return {
      variant: {
        default: null,
        parseHTML: (element: HTMLElement) =>
          element.getAttribute("data-f-tiptap-styled-paragraph-variant"),
        renderHTML: (attributes: { variant: string }) => ({
          "data-f-tiptap-styled-paragraph-variant": attributes.variant,
        }),
      },
    };
  },
});
