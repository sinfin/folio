import { mergeAttributes, Node, ReactNodeViewRenderer } from "@tiptap/react";
import { FolioTiptapNode } from "@/components/tiptap-extensions/folio-tiptap-node";

export type FolioTiptapNodeOptions = Record<string, never>;

/**
 * A TipTap node extension that creates a component wrapping API HTML content.
 */
export const FolioTiptapNodeExtension = Node.create<FolioTiptapNodeOptions>({
  name: "folioTiptapNode",

  group: "block",

  draggable: true,

  selectable: true,

  atom: true,

  code: true,

  isolating: true,

  addAttributes() {
    return {
      version: {
        default: 1,
      },
      type: {
        default: "",
      },
      data: {
        default: {},
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "div",
        getAttrs: (node) => {
          return JSON.parse(node.getAttribute("data-folio-tiptap-node-payload") || "{}");
        },
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes({ "data-folio-tiptap-node-payload": JSON.stringify(HTMLAttributes) }, HTMLAttributes),
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapNode);
  },
});

export default FolioTiptapNodeExtension;
