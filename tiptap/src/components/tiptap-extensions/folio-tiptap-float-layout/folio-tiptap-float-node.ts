import { Node, mergeAttributes } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';

export * from './folio-tiptap-float-layout-node';

export const FolioTiptapFloatNode = Node.create({
  name: 'folioTiptapFloat',
  isolating: true,
  content: 'block+',

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-float',
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-float"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['aside', mergeAttributes({ "class": "f-tiptap-float" }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});

export default FolioTiptapFloatNode;
