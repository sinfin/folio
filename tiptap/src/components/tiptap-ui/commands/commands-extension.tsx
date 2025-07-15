import { Extension, Editor } from "@tiptap/core";
import Suggestion from "@tiptap/suggestion";

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
          range: any;
          props: {
            command: (params: { editor: Editor; range: any }) => void;
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
