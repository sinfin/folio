import { Extension, Editor } from "@tiptap/core";
import Suggestion from "@tiptap/suggestion";
import type { Range } from "@tiptap/core";

interface CommandInterface {
  editor: Editor;
  range: Range;
  props: {
    command: ({ chain }: { chain: FolioEditorCommandChain }) => void;
  };
}

export const CommandsExtension = Extension.create({
  name: "commands",

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
});

export default CommandsExtension;
