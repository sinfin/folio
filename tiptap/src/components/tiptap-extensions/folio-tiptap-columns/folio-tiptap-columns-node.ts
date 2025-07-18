import { Node, mergeAttributes } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';

import { addOrDeleteColumn, createColumns, goToColumn } from './utils';

export * from './folio-tiptap-column-node';
// export * from './components/ColumnActionButton';

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    columns: {
      insertColumns: (attrs?: { count: number }) => ReturnType
      addColumnBefore: () => ReturnType
      addColumnAfter: () => ReturnType
      deleteColumn: () => ReturnType
    }
  }
}

export const FolioTiptapColumnsNode = Node.create({
  name: 'folioTiptapColumns',
  group: 'block',
  defining: true,
  isolating: true,
  allowGapCursor: false,
  content: 'folioTiptapColumn{1,}',
  draggable: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: 'f-tiptap-columns',
      },
    };
  },

  addAttributes() {
    return {
      count: {
        default: 2,
        parseHTML: element => element.getAttribute('data-f-tiptap-columns-count'),
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-columns"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', mergeAttributes({ "data-f-tiptap-columns-count": HTMLAttributes.count }, this.options.HTMLAttributes, HTMLAttributes), 0];
  },

  addCommands() {
    return {
      insertColumns:
        (attrs) =>
          ({ tr, dispatch, editor }) => {
            const node = createColumns(editor.schema, (attrs && attrs.count) || 2);

            if (dispatch) {
              const offset = tr.selection.anchor + 1;

              tr.replaceSelectionWith(node)
                .scrollIntoView()
                .setSelection(TextSelection.near(tr.doc.resolve(offset)));
            }

            return true;
          },
      addColumnBefore:
        () =>
          ({ dispatch, state }) => {
            return addOrDeleteColumn({ dispatch, state, type: 'addBefore' });
          },
      addColumnAfter:
        () =>
          ({ dispatch, state }) => {
            return addOrDeleteColumn({ dispatch, state, type: 'addAfter' });
          },
      deleteColumn:
        () =>
          ({ dispatch, state }) => {
            return addOrDeleteColumn({ dispatch, state, type: 'delete' });
          },
    };
  },

  addKeyboardShortcuts() {
    return {
      'Tab': () => {
        return goToColumn({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: 'after',
        });
      },
      'Shift-Tab': () => {
        return goToColumn({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: 'before',
        });
      },
    };
  },
});

export default FolioTiptapColumnsNode;
