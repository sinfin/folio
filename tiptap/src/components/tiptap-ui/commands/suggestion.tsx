import { computePosition } from "@floating-ui/dom";
import { ReactRenderer } from "@tiptap/react";
import { Editor } from "@tiptap/core";

import { CommandsList } from "./commands-list";
import { COMMANDS_POPUP_OPEN_EVENT_NAME } from "@/components/tiptap-commands/ui/commands-popup"

interface SuggestionProps {
  editor: Editor;
  range: any;
  clientRect: () => DOMRect;
  command: (item: any) => void;
  items: any[];
  query: string;
  event: KeyboardEvent;
}

const defaultItems = [
  {
    title: "Heading 1",
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor
        .chain()
        .focus()
        .deleteRange(range)
        .setNode("heading", { level: 1 })
        .run();
    },
  },
  {
    title: "Heading 2",
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor
        .chain()
        .focus()
        .deleteRange(range)
        .setNode("heading", { level: 2 })
        .run();
    },
  },
  {
    title: "Bold",
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor.chain().focus().deleteRange(range).setMark("bold").run();
    },
  },
  {
    title: "Italic",
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor.chain().focus().deleteRange(range).setMark("italic").run();
    },
  },
];

export const suggestion = {
  items: ({ query }: { editor: Editor; query: string }) => {
    return defaultItems
      .filter((item) =>
        item.title.toLowerCase().startsWith(query.toLowerCase()),
      )
      .slice(0, 5);
  },

  allowSpaces: false,

  startOfLine: true,

  render: () => {
    return {
      onStart: (props: SuggestionProps) => {
        console.log("suggestion onStart", props);
        const clientRect = props.clientRect()

        props.editor.chain().setMeta("hideDragHandle", true).setMeta("lockDragHandle", true).run()
        props.editor.chain().focus().deleteRange(props.range).run();

        const ref = document.elementFromPoint(clientRect.x, clientRect.y)
        const coords = { x: clientRect.x, y: clientRect.y + (clientRect.height < 100 ? clientRect.height : 0)  };

        window.dispatchEvent(new CustomEvent(COMMANDS_POPUP_OPEN_EVENT_NAME, { detail: { coords, ref } }));
      },

      onExit(props: SuggestionProps) {
        props.editor.chain().setMeta("hideDragHandle", false).setMeta("lockDragHandle", false).run()
        console.log("suggestion onExit");
      },
    };
  },
};

export default suggestion;
