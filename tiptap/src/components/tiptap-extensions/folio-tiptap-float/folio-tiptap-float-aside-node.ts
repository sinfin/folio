import { Node, mergeAttributes } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';

export * from './folio-tiptap-float-node';

export const FolioTiptapFloatAsideNode = Node.create({
  name: 'folioTiptapFloatAside',
  isolating: true,
  content: 'block+',

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-float__aside',
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-float__aside"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['aside', mergeAttributes({ "class": "f-tiptap-float__aside" }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },
});

export default FolioTiptapFloatAsideNode;
