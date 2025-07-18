import { Extension, Editor } from "@tiptap/core";
import Suggestion from "@tiptap/suggestion";
import type { Range } from "@tiptap/core";

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
        }: {
          editor: Editor;
          range: Range;
          props: {
            command: (params: {
              editor: Editor;
              range: Range;
            }) => void;
          };
        }) => {
          props.command({ editor, range });
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
