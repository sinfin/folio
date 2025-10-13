import { Node, mergeAttributes } from "@tiptap/core";
import { TextSelection } from "@tiptap/pm/state";

import {
  addOrDeleteColumn,
  createColumns,
  goToColumn,
} from "./folio-tiptap-columns-utils";

export * from "./folio-tiptap-column-node";

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    columns: {
      insertFolioTiptapColumns: () => ReturnType;
      addFolioTiptapColumnBefore: () => ReturnType;
      addFolioTiptapColumnAfter: () => ReturnType;
      deleteFolioTiptapColumn: () => ReturnType;
    };
  }
}

export const FolioTiptapColumnsNode = Node.create({
  name: "folioTiptapColumns",
  group: "block",
  defining: true,
  isolating: true,
  allowGapCursor: false,
  content: "folioTiptapColumn{1,}",
  draggable: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-columns",
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "div.f-tiptap-columns",
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes(
        {
          class: "f-tiptap-columns f-tiptap-avoid-external-layout",
        },
        this.options.HTMLAttributes,
        HTMLAttributes,
      ),
      0,
    ];
  },

  addCommands() {
    return {
      insertFolioTiptapColumns:
        () =>
        ({ tr, dispatch, editor }) => {
          const node = createColumns(editor.schema, 2);

          if (dispatch) {
            const offset = tr.selection.anchor + 1;

            tr.replaceSelectionWith(node)
              .scrollIntoView()
              .setSelection(TextSelection.near(tr.doc.resolve(offset)));
          }

          return true;
        },
      addFolioTiptapColumnBefore:
        () =>
        ({ dispatch, state }: CommandParams) => {
          if (!dispatch) return false;
          return addOrDeleteColumn({ dispatch, state, type: "addBefore" });
        },
      addFolioTiptapColumnAfter:
        () =>
        ({ dispatch, state }: CommandParams) => {
          if (!dispatch) return false;
          return addOrDeleteColumn({ dispatch, state, type: "addAfter" });
        },
      deleteFolioTiptapColumn:
        () =>
        ({ dispatch, state }: CommandParams) => {
          if (!dispatch) return false;
          return addOrDeleteColumn({ dispatch, state, type: "delete" });
        },
    };
  },

  addKeyboardShortcuts() {
    return {
      Tab: () => {
        return goToColumn({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: "after",
        });
      },
      "Shift-Tab": () => {
        return goToColumn({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: "before",
        });
      },
    };
  },
});

export default FolioTiptapColumnsNode;
