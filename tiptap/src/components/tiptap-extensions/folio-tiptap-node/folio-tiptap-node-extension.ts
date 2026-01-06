import { Node, ReactNodeViewRenderer } from "@tiptap/react";
import { FolioTiptapNode } from "@/components/tiptap-extensions/folio-tiptap-node";
import { Plugin } from "@tiptap/pm/state";
import type { CommandProps } from "@tiptap/core";
import { TextSelection } from "@tiptap/pm/state";
import { Fragment } from "@tiptap/pm/model";
import type { EditorView } from "@tiptap/pm/view";
import type { Slice } from "@tiptap/pm/model";

import { makeUniqueId } from "./make-unique-id";
import { moveFolioTiptapNode } from "./move-folio-tiptap-node";
import { postEditMessage } from "./post-edit-message";
import embedTypes from "@/../../data/embed/source/types.json";

const EMBED_URL_PATTERNS = Object.entries(embedTypes).reduce(
  (acc, [type, pattern]) => {
    acc[type] = new RegExp(pattern);
    return acc;
  },
  {} as Record<string, RegExp>,
);

function detectEmbedUrlType(url: string): string | null {
  for (const [type, pattern] of Object.entries(EMBED_URL_PATTERNS)) {
    if (pattern.test(url)) {
      return type;
    }
  }
  return null;
}

function detectFacebookIframe(html: string): boolean {
  return /<iframe[^>]*src="https:\/\/www\.facebook\.com\/plugins\/[^"]*"[^>]*>/.test(
    html,
  );
}

export type FolioTiptapNodeOptions = {
  nodes?: FolioTiptapNodeFromInput[];
  embedNodeClassName?: string;
};

declare module "@tiptap/core" {
  interface Commands<ReturnType> {
    folioTiptapNode: {
      moveFolioTiptapNodeUp: () => ReturnType;
      moveFolioTiptapNodeDown: () => ReturnType;
      editFolioTipapNode: () => ReturnType;
      removeFolioTiptapNode: () => ReturnType;
      insertFolioTiptapNode: (nodeHash: {
        attrs: Record<string, unknown>;
      }) => ReturnType;
    };
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
          let version;

          try {
            const raw = element.dataset.folioTiptapNodeVersion || "1";
            version = parseInt(raw, 10);
          } catch (error) {
            console.error("Error parsing folioTiptapNode version:", error);
            version = 1; // Fallback to default version
          }

          return version;
        },
      },
      type: {
        default: "",
        parseHTML: (element) => element.dataset.folioTiptapNodeType || "",
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
        },
      },
      uniqueId: {
        default: "",
        parseHTML: () => makeUniqueId(),
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: "div.f-tiptap-node",
        getAttrs: (element) => {
          if (typeof element === "string") return false;

          const nodeType = element.dataset.folioTiptapNodeType || "";

          // Check if this node type is allowed
          if (this.options.nodes && this.options.nodes.length > 0) {
            const allowedTypes = this.options.nodes.map((node) => node.type);
            if (!allowedTypes.includes(nodeType)) {
              return false; // Reject this node if type is not allowed
            }
          }

          return {
            version: parseInt(
              element.dataset.folioTiptapNodeVersion || "1",
              10,
            ),
            type: nodeType,
            data: (() => {
              try {
                return JSON.parse(element.dataset.folioTiptapNodeData || "{}");
              } catch (error) {
                console.error("Error parsing folioTiptapNode data:", error);
                return {};
              }
            })(),
            uniqueId: makeUniqueId(),
          };
        },
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      {
        class: "f-tiptap-node",
        "data-folio-tiptap-node-version": HTMLAttributes.version,
        "data-folio-tiptap-node-type": HTMLAttributes.type,
        "data-folio-tiptap-node-data": JSON.stringify(HTMLAttributes.data),
      },
    ];
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapNode, {
      // Allow all events to propagate to ProseMirror.
      // This fixes drop events not working when cursor is over this atomic node.
      stopEvent: () => false,
    });
  },

  addProseMirrorPlugins() {
    const pluginProps: {
      transformPastedHTML?: (html: string) => string;
      handlePaste?: (
        view: EditorView,
        event: ClipboardEvent,
        slice: Slice,
      ) => boolean;
    } = {
      transformPastedHTML: (html: string) => {
        // Only filter if we have allowed node types configured
        if (!this.options.nodes || this.options.nodes.length === 0) {
          return html;
        }

        // Extract allowed node types
        const allowedTypes = this.options.nodes.map((node) => node.type);

        // Create a temporary DOM to parse and filter the HTML
        const tempDiv = document.createElement("div");
        tempDiv.innerHTML = html;

        // Find all f-tiptap-node elements
        const nodeElements = tempDiv.querySelectorAll("div.f-tiptap-node");

        nodeElements.forEach((element) => {
          const nodeType =
            element.getAttribute("data-folio-tiptap-node-type") || "";

          // Remove unsupported node types
          if (!allowedTypes.includes(nodeType)) {
            element.remove();
          }
        });

        return tempDiv.innerHTML;
      },
    };

    // Build array of nodes with paste config
    const nodesWithPasteConfig: Array<{
      type: string;
      pattern: RegExp;
    }> = [];

    if (this.options.nodes) {
      this.options.nodes.forEach((node) => {
        if (node.config?.paste?.pattern) {
          try {
            // Convert Ruby regex pattern string to JavaScript RegExp
            // Ruby uses \A and \z for start/end anchors, JavaScript uses ^ and $
            let patternStr = node.config.paste.pattern;
            // Convert Ruby anchors to JavaScript anchors
            patternStr = patternStr.replace(/\\A/g, "^").replace(/\\z/g, "$");
            const regex = new RegExp(patternStr);
            nodesWithPasteConfig.push({
              type: node.type,
              pattern: regex,
            });
          } catch (error) {
            console.error(
              `Failed to create RegExp for node ${node.type}:`,
              error,
            );
          }
        }
      });
    }

    // Add handlePaste if we have paste configs or embedNodeClassName
    if (nodesWithPasteConfig.length > 0 || this.options.embedNodeClassName) {
      pluginProps.handlePaste = (view, event, _slice) => {
        const clipboardText = event.clipboardData?.getData("text/plain");
        const clipboardHTML = event.clipboardData?.getData("text/html");

        // First check paste patterns (before embed detection)
        if (nodesWithPasteConfig.length > 0) {
          const textToCheck = clipboardText?.trim() || clipboardHTML?.trim();

          if (textToCheck) {
            for (const nodeConfig of nodesWithPasteConfig) {
              if (nodeConfig.pattern.test(textToCheck)) {
                // Create paste placeholder node
                const placeholderNode =
                  view.state.schema.nodes.folioTiptapNodePastePlaceholder.create(
                    {
                      pasted_string: textToCheck,
                      target_node_type: nodeConfig.type,
                      uniqueId: makeUniqueId(),
                    },
                  );

                view.dispatch(
                  view.state.tr.replaceSelectionWith(placeholderNode),
                );
                return true; // Prevent default paste handling
              }
            }
          }
        }

        // Then check embed patterns (existing logic)
        if (this.options.embedNodeClassName) {
          if (clipboardText) {
            const trimmedText = clipboardText.trim();
            const embedType = detectEmbedUrlType(trimmedText);
            if (embedType) {
              // Create an embed node for URL embeds
              view.dispatch(
                view.state.tr.replaceSelectionWith(
                  this.type.create({
                    type: this.options.embedNodeClassName,
                    version: 1,
                    uniqueId: makeUniqueId(),
                    data: {
                      folio_embed_data: {
                        active: true,
                        type: embedType,
                        url: trimmedText,
                      },
                    },
                  }),
                ),
              );
              return true;
            }

            // Check if plain text contains Facebook iframe HTML
            if (detectFacebookIframe(trimmedText)) {
              // Create an embed node for Facebook HTML embeds pasted as text
              view.dispatch(
                view.state.tr.replaceSelectionWith(
                  this.type.create({
                    type: this.options.embedNodeClassName,
                    version: 1,
                    uniqueId: makeUniqueId(),
                    data: {
                      folio_embed_data: {
                        active: true,
                        html: trimmedText,
                      },
                    },
                  }),
                ),
              );
              return true;
            }
          }

          if (clipboardHTML && detectFacebookIframe(clipboardHTML)) {
            // Create an embed node for Facebook HTML embeds
            view.dispatch(
              view.state.tr.replaceSelectionWith(
                this.type.create({
                  type: this.options.embedNodeClassName,
                  version: 1,
                  uniqueId: makeUniqueId(),
                  data: {
                    folio_embed_data: {
                      active: true,
                      html: clipboardHTML,
                    },
                  },
                }),
              ),
            );
            return true;
          }
        }

        return false; // Let other handlers process the paste
      };
    }

    return [new Plugin({ props: pluginProps })];
  },

  addCommands() {
    return {
      insertFolioTiptapNode:
        (nodeHash: { attrs: Record<string, unknown> }) =>
        ({ tr, dispatch, editor }: CommandProps) => {
          const node = editor.schema.nodes.folioTiptapNode.createChecked(
            {
              ...nodeHash.attrs,
              uniqueId: nodeHash.attrs.uniqueId || makeUniqueId(),
            },
            null,
          );

          if (dispatch) {
            editor.view.dom.focus();

            const selection = tr.selection;
            const $pos = tr.doc.resolve(selection.anchor);

            // Check if we're at the end of a parent node (depth > 1 means we're inside something)
            // We use depth - 1 because the max-depth is the paragraph with slash
            const isAtEndOfParent =
              $pos.depth > 2 && $pos.pos + 1 === $pos.end($pos.depth - 1);

            if (isAtEndOfParent) {
              // Insert node + paragraph using fragment
              const paragraphNode = editor.schema.nodes.paragraph.create();
              const fragment = Fragment.from([node, paragraphNode]);

              // Replace the whole paragraph - the -1 is the node opening
              const start = $pos.start($pos.depth) - 1;

              // The +1 is the node closing
              const end = $pos.end($pos.depth) + 1;
              tr.replaceWith(start, end, fragment);

              // Set selection to the beginning of the paragraph (after the node)
              // start + folioTipapNode (leaf -> 1)
              const paragraphPos = start + 1;
              tr.setSelection(
                TextSelection.near(tr.doc.resolve(paragraphPos + 1)),
              );
            } else {
              // Just insert the node
              tr.replaceSelectionWith(node);

              // Move after the inserted node
              const offset = tr.selection.anchor;
              tr.setSelection(TextSelection.near(tr.doc.resolve(offset)));
            }

            tr.scrollIntoView();
            dispatch(tr);
          }

          return true;
        },

      moveFolioTiptapNodeDown:
        () =>
        ({ state, dispatch }: CommandProps) => {
          return moveFolioTiptapNode({ direction: "down", state, dispatch });
        },
      moveFolioTiptapNodeUp:
        () =>
        ({ state, dispatch }: CommandProps) => {
          return moveFolioTiptapNode({ direction: "up", state, dispatch });
        },
      editFolioTipapNode:
        () =>
        ({ state }: CommandProps) => {
          // @ts-expect-error - node does exist on selection!
          const node = state.selection.node;

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
          const node = state.selection.node;

          if (!node || node.type.name !== this.name) {
            return false;
          }

          const tr = state.tr;
          tr.deleteRange(state.selection.from, state.selection.to);
          dispatch!(tr);

          return true;
        },
    };
  },
});

export default FolioTiptapNodeExtension;
