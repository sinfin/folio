import { Extension, Editor } from "@tiptap/core";
import Suggestion from "@tiptap/suggestion";
import type { Range } from "@tiptap/core";
import { type EditorState, TextSelection, NodeSelection } from "@tiptap/pm/state";

interface CommandInterface {
  editor: Editor;
  range: Range;
  props: {
    command: ({ chain }: { chain: FolioEditorCommandChain }) => void;
  };
}

declare module '@tiptap/core' {
  interface Commands<ReturnType> {
    folioTiptapCommands: {
      triggerFolioTiptapCommand: (pos: number | null) => ReturnType;
    }
  }
}

export const FolioTiptapCommandsExtension = Extension.create({
  name: "folioTiptapCommands",

  addOptions() {
    return {
      suggestion: {
        char: "/",
        command: ({
          editor,
          range,
          props,
        }: CommandInterface) => {
          const chain = editor.chain()
          chain.focus()
          chain.deleteRange(range)

          props.command({ chain })

          chain.run();
        },
      },
    };
  },

  addProseMirrorPlugins() {
    return [
      Suggestion({
        editor: this.editor,
        ...this.options.suggestion,
      }),
    ];
  },

  addCommands() {
    return {
      triggerFolioTiptapCommand:
        (pos) =>
          ({ state, dispatch }: { state: EditorState; dispatch: any }) => {
            const resolvedPos = pos === null ? state.selection.$from : state.doc.resolve(pos);

            if (!resolvedPos) {
              console.error("Invalid resolved position");
              return false;
            }

            let node = resolvedPos.node(1)

            if (!node && !pos) {
              // For NodeSelection, get the selected node
              if (state.selection instanceof NodeSelection) {
                node = state.selection.node
              }
            }

            let shouldInsertParagraph = true
            let targetPos

            if (node && node.isLeaf) {
              targetPos = resolvedPos.after(1) + node.nodeSize;
            } else if (node && (node.type.name === "paragraph" && node.content.size === 0)) {
              shouldInsertParagraph = false
              targetPos = resolvedPos.start(1);
            } else {
              targetPos = resolvedPos.after(1);
            }

            // Insert a paragraph with "/" and place cursor after
            const tr = state.tr;

            if (shouldInsertParagraph) {
              const paragraph = state.schema.nodes.paragraph.create({}, [
                state.schema.text("/")
              ]);

              tr.insert(targetPos, paragraph);
            } else {
              // If the node is a paragraph with no content, just insert "/"
              const textNode = state.schema.text("/");
              tr.insert(targetPos, textNode);
            }

            // Place cursor after the "/"
            const newPos = targetPos + 1 + (shouldInsertParagraph ? 1 : 0);
            tr.setSelection(TextSelection.create(tr.doc, newPos));

            if (dispatch) {
              dispatch(tr);
            }

            return true;
          },
    };
  },
});

export default FolioTiptapCommandsExtension;
