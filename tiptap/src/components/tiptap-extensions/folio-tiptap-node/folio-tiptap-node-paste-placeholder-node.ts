import { Node, ReactNodeViewRenderer } from "@tiptap/react";
import { FolioTiptapNodePastePlaceholderComponent } from "./folio-tiptap-node-paste-placeholder";

const CLASS_NAME = "f-tiptap-node-paste-placeholder";

export const FolioTiptapNodePastePlaceholderNode = Node.create<
  Record<string, never>
>({
  name: "folioTiptapNodePastePlaceholder",

  group: "block",

  draggable: true,

  selectable: true,

  atom: true,

  isolating: true,

  renderHTML({ HTMLAttributes }: { HTMLAttributes: Record<string, unknown> }) {
    return ["div", { ...HTMLAttributes, class: CLASS_NAME }, 0];
  },

  addAttributes() {
    return {
      pasted_string: {
        default: "",
        parseHTML: (element: HTMLElement) =>
          element.getAttribute("data-pasted-string") || "",
        renderHTML: (attributes: { pasted_string: string }) => ({
          "data-pasted-string": attributes.pasted_string,
        }),
      },
      target_node_type: {
        default: "",
        parseHTML: (element: HTMLElement) =>
          element.getAttribute("data-target-node-type") || "",
        renderHTML: (attributes: { target_node_type: string }) => ({
          "data-target-node-type": attributes.target_node_type,
        }),
      },
      uniqueId: {
        default: "",
        parseHTML: (element: HTMLElement) =>
          element.getAttribute("data-unique-id") || "",
        renderHTML: (attributes: { uniqueId: string }) => ({
          "data-unique-id": attributes.uniqueId,
        }),
      },
    };
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapNodePastePlaceholderComponent, {
      // Allow all events to propagate to ProseMirror.
      // This fixes drop events not working when cursor is over this node.
      stopEvent: () => false,
    });
  },

  parseHTML() {
    return [
      {
        tag: `div.${CLASS_NAME}`,
        getAttrs: (element) => {
          if (typeof element === "string") return false;
          return {
            pasted_string: element.getAttribute("data-pasted-string") || "",
            target_node_type:
              element.getAttribute("data-target-node-type") || "",
            uniqueId: element.getAttribute("data-unique-id") || "",
          };
        },
      },
    ];
  },
});
