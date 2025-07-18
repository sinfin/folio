import { mergeAttributes, Node, ReactNodeViewRenderer } from "@tiptap/react";

export const FolioTiptapColumnNode = Node.create({
  name: 'folioTiptapColumn',
  content: 'block+',
  isolating: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-column',
      },
    };
  },

  addAttributes() {
    return {
      index: {
        default: 0,
        parseHTML: (element) => {
          const raw = element.getAttribute('data-f-tiptap-column-index')

          if (typeof raw === 'string') {
            return parseInt(raw, 10);
          } else if (typeof raw === 'number') {
            return raw;
          } else {
            return 0;
          }
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-column"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ "data-f-tiptap-column-index": HTMLAttributes.index }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});

export default FolioTiptapColumnNode;
