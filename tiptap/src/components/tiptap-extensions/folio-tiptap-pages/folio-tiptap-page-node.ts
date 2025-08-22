import { mergeAttributes, Node, ReactNodeViewRenderer } from "@tiptap/react";

export const FolioTiptapPageNode = Node.create({
  name: 'folioTiptapPage',
  content: 'block+',
  isolating: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-page',
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div.f-tiptap-page',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});

export default FolioTiptapPageNode;
