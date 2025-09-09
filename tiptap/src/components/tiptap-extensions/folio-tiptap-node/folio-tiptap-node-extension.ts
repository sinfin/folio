import { Node, ReactNodeViewRenderer } from "@tiptap/react";
import { FolioTiptapNode } from "@/components/tiptap-extensions/folio-tiptap-node";
import { Plugin } from "@tiptap/pm/state";
import type { CommandProps } from "@tiptap/core";
import { TextSelection } from '@tiptap/pm/state';
import { Fragment } from '@tiptap/pm/model';

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
      insertFolioTiptapNode: (nodeHash: any) => ReturnType
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
      insertFolioTiptapNode:
        (nodeHash: any) =>
          ({ tr, dispatch, editor }: CommandProps) => {
            const node = editor.schema.nodes.folioTiptapNode.createChecked({
              ...nodeHash.attrs,
              uniqueId: nodeHash.attrs.uniqueId || makeUniqueId(),
            }, null);

            if (dispatch) {
              editor.view.dom.focus()

              const selection = tr.selection;
              const $pos = tr.doc.resolve(selection.anchor);

              // Check if we're at the end of a parent node (depth > 1 means we're inside something)
              // We use depth - 1 because the max-depth is the paragraph with slash
              const isAtEndOfParent = $pos.depth > 2 && $pos.pos + 1 === $pos.end($pos.depth - 1);

              if (isAtEndOfParent) {
                // Insert node + paragraph using fragment
                const paragraphNode = editor.schema.nodes.paragraph.create();
                const fragment = Fragment.from([node, paragraphNode]);

                // Replace the whole paragraph - the -1 is the node opening
                const start = $pos.start($pos.depth) - 1

                // The +1 is the node closing
                const end = $pos.end($pos.depth) + 1
                tr.replaceWith(start, end, fragment);

                // Set selection to the beginning of the paragraph (after the node)
                // start + folioTipapNode (leaf -> 1)
                const paragraphPos = start + 1
                tr.setSelection(TextSelection.near(tr.doc.resolve(paragraphPos + 1)));
              } else {
                // Just insert the node
                tr.replaceSelectionWith(node);

                // Move after the inserted node
                const offset = tr.selection.anchor;
                tr.setSelection(TextSelection.near(tr.doc.resolve(offset)));
              }

              tr.scrollIntoView();
              dispatch(tr)
            }

            return true;
          },

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
