import { Extension, Editor } from "@tiptap/core";
import Suggestion from "@tiptap/suggestion";
import type { Range } from "@tiptap/core";
import { type EditorState, TextSelection } from "@tiptap/pm/state";

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
      triggerFolioTiptapCommand: (pos: number | null) => ({ state, dispatch }: { state: EditorState; dispatch: any }) => boolean;
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
        (pos: number | null) =>
          ({ state, dispatch }: { state: EditorState; dispatch: any }) => {
            const resolvedPos = pos === null ? state.selection.$from : state.doc.resolve(pos);

            if (!resolvedPos) {
              console.error("Invalid resolved position");
              return false;
            }

            const node = resolvedPos.node(1)

            let endPos

            if (node && (node.isLeaf || node.content.size === 0)) {
              endPos = node.pos + node.nodeSize;
            } else {
              endPos = resolvedPos.after(1);
            }

            // Insert a paragraph with "/" and place cursor after
            const tr = state.tr;
            const paragraph = state.schema.nodes.paragraph.create({}, [
              state.schema.text("/")
            ]);

            tr.insert(endPos, paragraph);

            // Place cursor after the "/"
            const newPos = endPos + 2; // +1 for paragraph node, +1 for the "/" character
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
