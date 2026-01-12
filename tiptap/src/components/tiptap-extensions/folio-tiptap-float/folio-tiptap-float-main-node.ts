import { Node, mergeAttributes } from "@tiptap/core";
import { ReactNodeViewRenderer } from "@tiptap/react";
import FolioTiptapFloatMainView from "./folio-tiptap-float-main-view";

export * from "./folio-tiptap-float-node";

export const FolioTiptapFloatMainNode = Node.create({
  name: "folioTiptapFloatMain",
  isolating: true,
  content: "block+",

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-float__main",
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "div.f-tiptap-float__main",
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes(
        { class: "f-tiptap-float__main" },
        this.options.HTMLAttributes,
        HTMLAttributes,
      ),
      0,
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapFloatMainView, {
      as: "main",
      className: "node-folioTiptapFloatMain f-tiptap-float__main",
      // Allow all events to propagate to ProseMirror.
      // This fixes drop events not working when cursor is over this node.
      stopEvent: () => false,
    });
  },
});

export default FolioTiptapFloatMainNode;
