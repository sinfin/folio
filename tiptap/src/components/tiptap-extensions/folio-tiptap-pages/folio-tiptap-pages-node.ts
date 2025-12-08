import { Node, mergeAttributes } from "@tiptap/core";
import { ReactNodeViewRenderer } from "@tiptap/react";
import { TextSelection } from "@tiptap/pm/state";

import {
  addOrDeletePage,
  createPages,
  goToPage,
  moveFolioTiptapPage,
} from "./folio-tiptap-pages-utils";
import { FolioTiptapPagesView } from "./folio-tiptap-pages-view";

export * from "./folio-tiptap-page-node";

export const TRANSLATIONS = {
  cs: {
    label: "Stránkovaný obsah",
  },
  en: {
    label: "Paged content",
  },
};

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    folioTiptapPages: {
      insertFolioTiptapPages: () => ReturnType;
      addFolioTiptapPageBefore: () => ReturnType;
      addFolioTiptapPageAfter: () => ReturnType;
      deleteFolioTiptapPage: () => ReturnType;
      moveFolioTiptapPageUp: () => ReturnType;
      moveFolioTiptapPageDown: () => ReturnType;
    };
  }
}

export const FolioTiptapPagesNode = Node.create({
  name: "folioTiptapPages",
  group: "block",
  defining: true,
  isolating: true,
  allowGapCursor: false,
  content: "folioTiptapPage{2,}",
  draggable: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-pages",
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "div.f-tiptap-pages",
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes(
        {
          class: "f-tiptap-pages",
        },
        this.options.HTMLAttributes,
        HTMLAttributes,
      ),
      0,
    ];
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
        ({ dispatch, state }: CommandParams) => {
          return addOrDeletePage({ dispatch, state, type: "addBefore" });
        },
      addFolioTiptapPageAfter:
        () =>
        ({ dispatch, state }: CommandParams) => {
          return addOrDeletePage({ dispatch, state, type: "addAfter" });
        },
      deleteFolioTiptapPage:
        () =>
        ({ dispatch, state }: CommandParams) => {
          return addOrDeletePage({ dispatch, state, type: "delete" });
        },
      moveFolioTiptapPageUp:
        () =>
        ({ dispatch, state }: CommandParams) => {
          return moveFolioTiptapPage({ state, dispatch, type: "up" });
        },
      moveFolioTiptapPageDown:
        () =>
        ({ dispatch, state }: CommandParams) => {
          return moveFolioTiptapPage({ state, dispatch, type: "down" });
        },
    };
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapPagesView, {
      className: "node-folioTiptapPages f-tiptap-pages",
    });
  },

  addKeyboardShortcuts() {
    return {
      Tab: () => {
        return goToPage({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: "after",
        });
      },
      "Shift-Tab": () => {
        return goToPage({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
          type: "before",
        });
      },
    };
  },
});

export default FolioTiptapPagesNode;
