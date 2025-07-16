import { computePosition } from "@floating-ui/dom";
import { ReactRenderer } from "@tiptap/react";
import { Editor } from "@tiptap/core";

import { CommandsList } from "./commands-list";

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
    title: "Heading 2",
    keymap: "##",
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
    title: "Heading 3",
    keymap: "###",
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor
        .chain()
        .focus()
        .deleteRange(range)
        .setNode("heading", { level: 3 })
        .run();
    },
  },
  {
    title: "Heading 4",
    keymap: "####",
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor
        .chain()
        .focus()
        .deleteRange(range)
        .setNode("heading", { level: 4 })
        .run();
    },
  },
  {
    title: "Bold",
    keymap: "C-b",
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor.chain().focus().deleteRange(range).setMark("bold").run();
    },
  },
  {
    title: "Italic",
    keymap: "C-i",
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

  render: () => {
    let component: ReactRenderer | null = null;

    function repositionComponent(clientRect: DOMRect) {
      if (!component || !component.element) {
        return;
      }

      const virtualElement = {
        getBoundingClientRect() {
          return clientRect;
        },
      };

      computePosition(virtualElement, component.element as HTMLElement, {
        placement: "bottom-start",
      }).then((pos) => {
        Object.assign((component!.element as HTMLElement).style, {
          left: `${pos.x}px`,
          top: `${pos.y}px`,
          position: pos.strategy === "fixed" ? "fixed" : "absolute",
        });
      });
    }

    return {
      onStart: (props: SuggestionProps) => {
        console.log("suggestion onStart", component);
        props.editor.chain().setMeta("hideDragHandle", true).setMeta("lockDragHandle", true).run()

        component = new ReactRenderer(CommandsList, {
          props,
          editor: props.editor,
        });

        console.log("suggestion onStart", component);
        document.body.appendChild(component.element);
        repositionComponent(props.clientRect());
      },

      onUpdate(props: SuggestionProps) {
        console.log("suggestion onUpdate", component);
        component?.updateProps(props);
        repositionComponent(props.clientRect());
      },

      onKeyDown(props: SuggestionProps) {
        console.log("suggestion onKeyDown", component);
        if (props.event.key === "Escape") {
          if (component?.element) {
            document.body.removeChild(component.element);
            component.destroy();
          }

          return true;
        }

        return (
          component?.ref as { onKeyDown: (props: SuggestionProps) => boolean }
        )?.onKeyDown(props);
      },

      onExit(props: SuggestionProps) {
        console.log("suggestion onExit", component);
        props.editor.chain().setMeta("hideDragHandle", false).setMeta("lockDragHandle", false).run()
        if (!component) return;

        if (component.element && document.body.contains(component.element)) {
          document.body.removeChild(component.element);
        }
        component.destroy();
      },
    };
  },
};

export default suggestion;
