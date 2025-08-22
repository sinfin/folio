import { mergeAttributes, Node, ReactNodeViewRenderer } from "@tiptap/react";
import { findParentNode } from "@tiptap/core";
import { FolioTiptapNode } from "@/components/tiptap-extensions/folio-tiptap-node";
import { type EditorState } from "@tiptap/pm/state";

import { makeUniqueId } from './make-unique-id';
import { moveFolioTiptapNode } from './move-folio-tiptap-node';
import { postEditMessage } from './post-edit-message';

export type FolioTiptapNodeOptions = Record<string, never>;

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
        parseHTML: (element) => makeUniqueId()
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div.f-tiptap-node',
        getAttrs: (element) => {
          if (typeof element === 'string') return false;
          return {
            version: parseInt(element.dataset.folioTiptapNodeVersion || "1", 10),
            type: element.dataset.folioTiptapNodeType || "",
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

  addCommands() {
    return {
      moveFolioTiptapNodeDown:
        () =>
          ({ state, dispatch }: { state: EditorState; dispatch: any }) => {
            return moveFolioTiptapNode({ direction: "down", state, dispatch })
          },
      moveFolioTiptapNodeUp:
        () =>
          ({ state, dispatch }: { state: EditorState; dispatch: any }) => {
            return moveFolioTiptapNode({ direction: "up", state, dispatch })
          },
      editFolioTipapNode:
        () =>
          ({ state, dispatch }: { state: EditorState; dispatch: any }) => {
            // @ts-ignore - node does exist on selection!
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
          ({ state, dispatch }: { state: EditorState; dispatch: any }) => {
            // @ts-ignore - node does exist on selection!
            const node = state.selection.node

            if (!node || node.type.name !== this.name) {
              return false;
            }

            const tr = state.tr;
            tr.deleteRange(state.selection.from, state.selection.to);
            dispatch(tr);

            return true
          },
    };
  },
});

export default FolioTiptapNodeExtension;
