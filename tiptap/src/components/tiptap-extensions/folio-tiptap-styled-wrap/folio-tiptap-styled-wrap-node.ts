import { Node, mergeAttributes } from '@tiptap/core';

export const FolioTiptapStyledWrap = Node.create({
  name: "folioTiptapStyledWrap",
  defining: false,
  isolating: true,
  allowGapCursor: false,
  content: 'block+',
  group: "block",

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-styled-wrap"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ["div", { ...HTMLAttributes, class: "f-tiptap-styled-wrap" }, 0];
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
          element.getAttribute("data-f-tiptap-styled-wrap-variant"),
        renderHTML: (attributes: { variant: string }) => ({
          "data-f-tiptap-styled-wrap-variant": attributes.variant,
        }),
      },
    };
  },
});
