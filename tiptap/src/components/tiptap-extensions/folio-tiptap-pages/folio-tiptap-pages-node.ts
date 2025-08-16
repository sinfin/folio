import { Node, mergeAttributes } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';

import translate from "@/lib/i18n";

import { addOrDeletePage, createPages, goToPage } from './folio-tiptap-pages-utils';

export * from './folio-tiptap-page-node';

export const TRANSLATIONS = {
  cs: {
    label: "Stránkovaný obsah",
  },
  en: {
    label: "Paged content"
  }
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    pages: {
      insertFolioTiptapPages: () => ReturnType
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
        "data-f-tiptap-pages-label": translate(TRANSLATIONS, "label"),
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
      "class": "f-tiptap-pages",
    }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },

  addCommands() {
    return {
      insertFolioTiptapPages:
        () =>
          ({ tr, dispatch, editor }) => {
            const node = createPages(editor.schema, 2);

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
