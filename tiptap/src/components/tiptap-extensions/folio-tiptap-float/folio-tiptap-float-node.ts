import { Node, mergeAttributes } from "@tiptap/core";

import {
  insertFolioTiptapFloat,
  setFolioTiptapFloatAttributes,
  goToFolioTiptapFloatAsideOrMain,
  type InsertFolioTiptapFloatArgs,
  type SetFloatLayoutAttributesAttrs,
  type SetFloatLayoutAttributesArgs,
} from "./folio-tiptap-float-utils";

export * from "./folio-tiptap-float-node";
// export * from './components/ColumnActionButton';

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    folioTiptapFloat: {
      insertFolioTiptapFloat: () => ReturnType;
      setFolioTiptapFloatAttributes: (
        attrs: SetFloatLayoutAttributesAttrs,
      ) => ReturnType;
    };
  }
}

export const FolioTiptapFloatNode = Node.create({
  name: "folioTiptapFloat",
  group: "block",
  defining: true,
  isolating: true,
  allowGapCursor: false,
  content: "folioTiptapFloatAside{1} folioTiptapFloatMain{1}",
  draggable: false,

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-float",
      },
    };
  },

  addAttributes() {
    return {
      side: {
        default: "left",
        parseHTML: (element) =>
          element.getAttribute("data-f-tiptap-float-side") || "left",
      },
      size: {
        default: "medium",
        parseHTML: (element) =>
          element.getAttribute("data-f-tiptap-float-size") || "medium",
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
    return [
      "div",
      mergeAttributes(
        {
          "class": "f-tiptap-float f-tiptap-avoid-external-layout",
          "data-f-tiptap-float-side": HTMLAttributes.side,
          "data-f-tiptap-float-size": HTMLAttributes.size,
        },
        this.options.HTMLAttributes,
        HTMLAttributes,
      ),
      0,
    ];
  },

  addCommands() {
    return {
      insertFolioTiptapFloat:
        () =>
        ({ tr, dispatch, editor }) => {
          return insertFolioTiptapFloat({ tr, dispatch, editor });
        },
      setFolioTiptapFloatAttributes:
        (attrs: SetFloatLayoutAttributesAttrs) =>
        ({ tr, dispatch, state, editor }) => {
          return setFolioTiptapFloatAttributes({
            attrs,
            tr,
            dispatch,
            state,
            editor,
          });
        },
    };
  },

  addKeyboardShortcuts() {
    return {
      'Tab': () => {
        return goToFolioTiptapFloatAsideOrMain({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
        });
      },
      'Shift-Tab': () => {
        return goToFolioTiptapFloatAsideOrMain({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
        });
      },
    };
  },
});

export default FolioTiptapFloatNode;
