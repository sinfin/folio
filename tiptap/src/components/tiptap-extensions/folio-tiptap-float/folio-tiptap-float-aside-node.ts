import { Node, mergeAttributes } from "@tiptap/core";
import { ReactNodeViewRenderer } from "@tiptap/react";
import FolioTiptapFloatAsideView from "./folio-tiptap-float-aside-view";

export * from "./folio-tiptap-float-node";

export const FolioTiptapFloatAsideNode = Node.create({
  name: "folioTiptapFloatAside",
  isolating: true,
  content: "block+",

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-float__aside",
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "aside.f-tiptap-float__aside",
      },
      {
        tag: "div.f-tiptap-float__aside",
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "aside",
      mergeAttributes(
        { class: "f-tiptap-float__aside" },
        this.options.HTMLAttributes,
        HTMLAttributes,
      ),
      0,
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapFloatAsideView, {
      as: "aside",
      className: "node-folioTiptapFloatAside f-tiptap-float__aside",
      // Allow all events to propagate to ProseMirror.
      // This fixes drop events not working when cursor is over this node.
      stopEvent: () => false,
    });
  },
});

export default FolioTiptapFloatAsideNode;
