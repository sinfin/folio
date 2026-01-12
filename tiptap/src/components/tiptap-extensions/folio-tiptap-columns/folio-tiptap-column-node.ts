import { mergeAttributes, Node } from "@tiptap/react";
import { ReactNodeViewRenderer } from "@tiptap/react";
import FolioTiptapColumnView from "./folio-tiptap-column-view";

export const FolioTiptapColumnNode = Node.create({
  name: "folioTiptapColumn",
  content: "block+",
  isolating: true,

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-column",
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "div.f-tiptap-column",
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes(this.options.HTMLAttributes, HTMLAttributes),
      0,
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapColumnView, {
      className: "node-folioTiptapColumn f-tiptap-column",
      // Allow all events to propagate to ProseMirror.
      // This fixes drop events not working when cursor is over this node.
      stopEvent: () => false,
    });
  },
});

export default FolioTiptapColumnNode;
