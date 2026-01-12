import { mergeAttributes, Node, ReactNodeViewRenderer } from "@tiptap/react";
import { FolioTiptapPageView } from "./folio-tiptap-page-view";

export const FolioTiptapPageNode = Node.create({
  name: "folioTiptapPage",
  content: "block+",
  isolating: true,

  addAttributes() {
    return {
      collapsed: {
        default: false,
        parseHTML: (element) =>
          element.getAttribute("data-collapsed") === "true",
        renderHTML: (attributes) => {
          if (attributes.collapsed) {
            return {
              "data-collapsed": "true",
            };
          }
          return {};
        },
      },
    };
  },

  addOptions() {
    return {
      HTMLAttributes: {
        class: "f-tiptap-page",
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "div.f-tiptap-page",
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
    return ReactNodeViewRenderer(FolioTiptapPageView, {
      // Allow all events to propagate to ProseMirror.
      // This fixes drop events not working when cursor is over this node.
      stopEvent: () => false,
    });
  },
});

export default FolioTiptapPageNode;
