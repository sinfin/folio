import { Node, mergeAttributes } from "@tiptap/core";

import {
  insertFolioTiptapFloatLayout,
  setFloatLayoutAttributes,
  goToFloatOrBack,
  type InsertFolioTiptapFloatLayoutArgs,
  type SetFloatLayoutAttributesAttrs,
  type SetFloatLayoutAttributesArgs,
} from "./folio-tiptap-float-utils";

export * from "./folio-tiptap-float-layout-node";
// export * from './components/ColumnActionButton';

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    folioTiptapFloatLayout: {
      insertFolioTiptapFloatLayout: () => ReturnType;
      setFloatLayoutAttributes: (
        attrs: SetFloatLayoutAttributesAttrs,
      ) => ReturnType;
    };
  }
}

export const FolioTiptapFloatLayoutNode = Node.create({
  name: "folioTiptapFloatLayout",
  group: "block",
  defining: true,
  isolating: true,
  allowGapCursor: false,
  content: "folioTiptapFloat block+",
  draggable: false,

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-float-layout",
      },
    };
  },

  addAttributes() {
    return {
      side: {
        default: "left",
        parseHTML: (element) =>
          element.getAttribute("data-f-tiptap-float-layout-side") || "left",
      },
      size: {
        default: "medium",
        parseHTML: (element) =>
          element.getAttribute("data-f-tiptap-float-layout-size") || "medium",
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-float-layout"]',
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes(
        {
          "data-f-tiptap-float-layout-side": HTMLAttributes.side,
          "data-f-tiptap-float-layout-size": HTMLAttributes.size,
        },
        this.options.HTMLAttributes,
        HTMLAttributes,
      ),
      0,
    ];
  },

  addCommands() {
    return {
      insertFolioTiptapFloatLayout:
        () =>
        ({ tr, dispatch, editor }) => {
          return insertFolioTiptapFloatLayout({ tr, dispatch, editor });
        },
      setFloatLayoutAttributes:
        (attrs: SetFloatLayoutAttributesAttrs) =>
        ({ tr, dispatch, state, editor }) => {
          return setFloatLayoutAttributes({
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
        return goToFloatOrBack({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
        });
      },
      'Shift-Tab': () => {
        return goToFloatOrBack({
          state: this.editor.state,
          dispatch: this.editor.view.dispatch,
        });
      },
    };
  },
});

export default FolioTiptapFloatLayoutNode;
