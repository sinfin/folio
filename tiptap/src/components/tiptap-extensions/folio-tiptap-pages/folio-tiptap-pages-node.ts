import { Node, mergeAttributes } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';

import { addOrDeletePage, createPages, goToPage } from './folio-tiptap-pages-utils';

export * from './folio-tiptap-page-node';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    pages: {
      insertFolioTiptapPages: (attrs?: { count: number }) => ReturnType
      addFolioTiptapPageBefore: () => ReturnType
      addFolioTiptapPageAfter: () => ReturnType
      deleteFolioTiptapPage: () => ReturnType
    }
  }
}

export const FolioTiptapPagesNode = Node.create({
  name: 'folioTiptapPages',
  group: 'block',
  defining: true,
  isolating: true,
  allowGapCursor: false,
  content: 'folioTiptapPage{2,}',
  draggable: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-pages',
      },
    };
  },

  addAttributes() {
    return {
      count: {
        default: 2,
        parseHTML: element => element.getAttribute('data-f-tiptap-pages-count'),
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-pages"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({
      "data-f-tiptap-pages-count": HTMLAttributes.count,
      "class": "f-tiptap-pages",
    }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },

  addCommands() {
    return {
      insertFolioTiptapPages:
        (attrs) =>
          ({ tr, dispatch, editor }) => {
            const node = createPages(editor.schema, (attrs && attrs.count) || 2);

            if (dispatch) {
              const offset = tr.selection.anchor + 1;

              tr.replaceSelectionWith(node)
                .scrollIntoView()
                .setSelection(TextSelection.near(tr.doc.resolve(offset)));
            }

            return true;
          },
      addFolioTiptapPageBefore:
        () =>
          ({ dispatch, state }) => {
            return addOrDeletePage({ dispatch, state, type: 'addBefore' });
          },
      addFolioTiptapPageAfter:
        () =>
          ({ dispatch, state }) => {
            return addOrDeletePage({ dispatch, state, type: 'addAfter' });
          },
      deleteFolioTiptapPage:
        () =>
          ({ dispatch, state }) => {
            return addOrDeletePage({ dispatch, state, type: 'delete' });
          },
    };
  },

  addKeyboardShortcuts() {
    return {
      'Tab': () => {
        return goToPage({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: 'after',
        });
      },
      'Shift-Tab': () => {
        return goToPage({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: 'before',
        });
      },
    };
  },
});

export default FolioTiptapPagesNode;
