import { Node, mergeAttributes } from '@tiptap/core';

export * from './folio-tiptap-float-node';

export const FolioTiptapFloatMainNode = Node.create({
  name: 'folioTiptapFloatMain',
  isolating: true,
  content: 'block+',

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-float__main',
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div.f-tiptap-float__main',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ "class": "f-tiptap-float__main" }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});

export default FolioTiptapFloatMainNode;
