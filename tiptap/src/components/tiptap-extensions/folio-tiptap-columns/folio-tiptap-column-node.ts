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

  parseHTML() {
    return [
      {
        tag: 'div.f-tiptap-column',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});

export default FolioTiptapColumnNode;
