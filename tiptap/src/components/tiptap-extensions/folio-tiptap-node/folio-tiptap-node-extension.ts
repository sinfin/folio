import { Node, ReactNodeViewRenderer } from "@tiptap/react";
import { FolioTiptapNode } from "@/components/tiptap-extensions/folio-tiptap-node";
import { Plugin } from "@tiptap/pm/state";
import type { CommandProps } from "@tiptap/core";

import { makeUniqueId } from './make-unique-id';
import { moveFolioTiptapNode } from './move-folio-tiptap-node';
import { postEditMessage } from './post-edit-message';

export type FolioTiptapNodeOptions = {
  nodes?: FolioTiptapNodeFromInput[];
};

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    folioTiptapNode: {
      moveFolioTiptapNodeUp: () => ReturnType
      moveFolioTiptapNodeDown: () => ReturnType
      editFolioTipapNode: () => ReturnType
      removeFolioTiptapNode: () => ReturnType
    }
  }
}

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
        parseHTML: () => makeUniqueId()
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div.f-tiptap-node',
        getAttrs: (element) => {
          if (typeof element === 'string') return false;
          
          const nodeType = element.dataset.folioTiptapNodeType || "";
          
          // Check if this node type is allowed
          if (this.options.nodes && this.options.nodes.length > 0) {
            const allowedTypes = this.options.nodes.map(node => node.type);
            if (!allowedTypes.includes(nodeType)) {
              return false; // Reject this node if type is not allowed
            }
          }
          
          return {
            version: parseInt(element.dataset.folioTiptapNodeVersion || "1", 10),
            type: nodeType,
            data: (() => {
              try {
                return JSON.parse(element.dataset.folioTiptapNodeData || "{}");
              } catch (error) {
                console.error("Error parsing folioTiptapNode data:", error);
                return {};
              }
            })(),
            uniqueId: makeUniqueId()
          };
        },
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
      }
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapNode);
  },

  addProseMirrorPlugins() {
    return [
      new Plugin({
        props: {
          transformPastedHTML: (html: string) => {
            // Only filter if we have allowed node types configured
            if (!this.options.nodes || this.options.nodes.length === 0) {
              return html;
            }

            // Extract allowed node types
            const allowedTypes = this.options.nodes.map(node => node.type);

            // Create a temporary DOM to parse and filter the HTML
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;
            
            // Find all f-tiptap-node elements
            const nodeElements = tempDiv.querySelectorAll('div.f-tiptap-node');
            
            nodeElements.forEach((element) => {
              const nodeType = element.getAttribute('data-folio-tiptap-node-type') || '';
              
              // Remove unsupported node types
              if (!allowedTypes.includes(nodeType)) {
                element.remove();
              }
            });
            
            return tempDiv.innerHTML;
          },
        },
      }),
    ];
  },

  addCommands() {
    return {
      moveFolioTiptapNodeDown:
        () =>
          ({ state, dispatch }: CommandProps) => {
            return moveFolioTiptapNode({ direction: "down", state, dispatch })
          },
      moveFolioTiptapNodeUp:
        () =>
          ({ state, dispatch }: CommandProps) => {
            return moveFolioTiptapNode({ direction: "up", state, dispatch })
          },
      editFolioTipapNode:
        () =>
          ({ state }: CommandProps) => {
            // @ts-expect-error - node does exist on selection!
            const node = state.selection.node

            if (!node || node.type.name !== this.name) {
              return false;
            }

            const { uniqueId, ...attrsWithoutUniqueId } = node.attrs;
            postEditMessage(attrsWithoutUniqueId, uniqueId);

            return true;
          },
      removeFolioTiptapNode:
        () =>
          ({ state, dispatch }: CommandProps) => {
            // @ts-expect-error - node does exist on selection!
            const node = state.selection.node

            if (!node || node.type.name !== this.name) {
              return false;
            }

            const tr = state.tr;
            tr.deleteRange(state.selection.from, state.selection.to);
            dispatch!(tr);

            return true
          },
    };
  },
});

export default FolioTiptapNodeExtension;
