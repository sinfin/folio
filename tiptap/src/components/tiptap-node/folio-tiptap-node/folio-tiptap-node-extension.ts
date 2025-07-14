import { mergeAttributes, Node, ReactNodeViewRenderer } from "@tiptap/react";
import { FolioTiptapNode } from "@/components/tiptap-node/folio-tiptap-node/folio-tiptap-node";

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
    // return [{ tag: 'div[data-type="image-upload"]' }]
    return [];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes({ "data-type": "folio-tiptap-node" }, HTMLAttributes),
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapNode);
  },
});

export default FolioTiptapNodeExtension;
