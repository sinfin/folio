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
        tag: 'div.f-tiptap-styled-wrap',
        getAttrs: (element) => {
          if (typeof element === 'string') return false;
          return {
            variant: element.getAttribute('data-f-tiptap-styled-wrap-variant') || null,
          };
        },
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ["div", { ...HTMLAttributes, class: "f-tiptap-styled-wrap f-tiptap-avoid-external-layout" }, 0];
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
