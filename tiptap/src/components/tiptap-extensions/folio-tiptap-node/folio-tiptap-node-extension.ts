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
        parseHTML: (element) => {
          let version

          try {
            const raw = element.dataset.folioTiptapNodeVersion || "1"
            version = parseInt(raw, 10);
          } catch (error) {
            console.error("Error parsing folioTiptapNode version:", error);
            version = 1; // Fallback to default version
          }

          return version
        }
      },
      type: {
        default: "",
        parseHTML: (element) => element.dataset.folioTiptapNodeType || ""
      },
      data: {
        default: {},
        parseHTML: (element) => {
          const raw = element.dataset.folioTiptapNodeData || "{}";
          try {
            return JSON.parse(raw);
          } catch (error) {
            console.error("Error parsing folioTiptapNode data:", error);
            return {};
          }
        }
      },
      uniqueId: {
        default: "",
        parseHTML: (element) => element.dataset.folioTiptapNodeUniqueId || ""
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div[class="f-tiptap-node"]',
      },
    ]
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      {
        "class": "f-tiptap-node",
        "data-folio-tiptap-node-version": HTMLAttributes.version,
        "data-folio-tiptap-node-type": HTMLAttributes.type,
        "data-folio-tiptap-node-data": JSON.stringify(HTMLAttributes.data),
        "data-folio-tiptap-node-unique-id": HTMLAttributes.uniqueId,
      }
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapNode);
  },
});

export default FolioTiptapNodeExtension;
