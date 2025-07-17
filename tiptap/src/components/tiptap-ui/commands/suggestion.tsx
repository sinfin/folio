import { computePosition, flip, offset } from "@floating-ui/dom";
import { ReactRenderer } from "@tiptap/react";
import { Editor } from "@tiptap/core";

import { CommandsList, type CommandItem, type CommandGroup } from "./commands-list";
import { CommandsListBackdrop } from "./commands-list-backdrop";

import { headingIcons } from "@/components/tiptap-ui/heading-button/heading-button";
import { markIcons } from "@/components/tiptap-ui/mark-button/mark-button";

// Local Range type for compatibility with TipTap commands
type Range = { from: number; to: number };

interface SuggestionProps {
  editor: Editor;
  range: Range;
  clientRect: () => DOMRect;
  command: (item: CommandItem) => void;
  items: CommandGroup[];
  query: string;
  event: KeyboardEvent;
}

export const makeSuggestionItems = (groups: CommandGroup[]) => {
  return ({ query }: { editor: Editor; query: string }) => {
    return translateTitles(groups)
      .map((group: CommandGroup): CommandGroup | null => {
        const matchingItems = group.items.filter((item: CommandItem) => {
          const title =
            typeof item.title === "string"
              ? item.title
              : item.title[document.documentElement.lang as "cs" | "en"] ||
                item.title.en;
          return title.toLowerCase().indexOf(query.toLowerCase()) !== -1;
        });
        if (matchingItems.length > 0) {
          return { ...group, items: matchingItems };
        }
        return null;
      })
      .filter((group): group is CommandGroup => group !== null);
  };
};

export const defaultGroup: CommandGroup = {
  title: { cs: "Text", en: "Text" },
  items: [
    {
      title: { cs: "Titulek H2", en: "Heading H2" },
      keymap: "##",
      icon: headingIcons[2],
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor
          .chain()
          .focus()
          .deleteRange(range)
          .setNode("heading", { level: 2 })
          .run();
      },
    },
    {
      title: { cs: "Titulek H3", en: "Heading H3" },
      keymap: "###",
      icon: headingIcons[3],
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor
          .chain()
          .focus()
          .deleteRange(range)
          .setNode("heading", { level: 3 })
          .run();
      },
    },
    {
      title: { cs: "Titulek H4", en: "Heading H4" },
      keymap: "####",
      icon: headingIcons[4],
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor
          .chain()
          .focus()
          .deleteRange(range)
          .setNode("heading", { level: 4 })
          .run();
      },
    },
    {
      title: { cs: "Tučné písmo", en: "Bold" },
      keymap: "C-b",
      icon: markIcons["bold"],
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor.chain().focus().deleteRange(range).setMark("bold").run();
      },
    },
    {
      title: { cs: "Kurzíva", en: "Italic" },
      keymap: "C-i",
      icon: markIcons["italic"],
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor.chain().focus().deleteRange(range).setMark("italic").run();
      },
    },
  ],
};

const translateTitles = (groups: CommandGroup[]): CommandGroup[] => {
  const lang = document.documentElement.lang as "cs" | "en";
  return groups.map((group: CommandGroup) => ({
    ...group,
    title:
      typeof group.title === "string"
        ? group.title
        : group.title[lang] || group.title.en,
    items: group.items.map((item: CommandItem) => ({
      ...item,
      title:
        typeof item.title === "string"
          ? item.title
          : item.title[lang] || item.title.en,
    })),
  }));
};

export const suggestion = {
  items: makeSuggestionItems([defaultGroup]),

  allowSpaces: false,

  render: () => {
    let component: ReactRenderer | null = null;
    let backdrop: ReactRenderer | null = null

    function repositionComponent(clientRect: DOMRect, action: string) {
      if (!component || !component.element) {
        return;
      }

      const virtualElement = {
        getBoundingClientRect() {
          return clientRect;
        },
      };

      let placement: import("@floating-ui/dom").Placement | undefined =
        "bottom-start";

      if (
        action === "update" &&
        component &&
        component.element &&
        (component.element as HTMLElement).dataset.placement
      ) {
        placement = (component.element as HTMLElement).dataset
          .placement as import("@floating-ui/dom").Placement;
      }

      computePosition(virtualElement, component.element as HTMLElement, {
        placement,
        middleware: [flip(), offset(12)],
      }).then((pos) => {
        (component!.element as HTMLElement).dataset.placement = pos.placement;
        Object.assign((component!.element as HTMLElement).style, {
          left: `${pos.x}px`,
          top: `${pos.y}px`,
          zIndex: "11",
          position: pos.strategy === "fixed" ? "fixed" : "absolute",
        });

        Object.assign((backdrop!.element as HTMLElement).style, {
          inset: 0,
          position: pos.strategy === "fixed" ? "fixed" : "absolute",
          zIndex: "10",
        });
      });
    }

    return {
      onStart: (props: SuggestionProps) => {
        // console.log("suggestion onStart", component);
        props.editor
          .chain()
          .setMeta("hideDragHandle", true)
          .setMeta("lockDragHandle", true)
          .run();

        backdrop = new ReactRenderer(CommandsListBackdrop, {
          props: { ...props, query: props.query },
          editor: props.editor,
        })
        document.body.appendChild(backdrop.element)

        component = new ReactRenderer(CommandsList, {
          props: { ...props, query: props.query },
          editor: props.editor,
        });
        document.body.appendChild(component.element);

        repositionComponent(props.clientRect(), "start");
      },

      onUpdate(props: SuggestionProps) {
        // console.log("suggestion onUpdate", component);
        component?.updateProps(props);
        repositionComponent(props.clientRect(), "update");
      },

      onKeyDown(props: SuggestionProps) {
        if (props.event.key === "Escape") {
          if (
            component?.ref &&
            typeof (component.ref as { onEscape?: () => void }).onEscape ===
              "function"
          ) {
            (component.ref as { onEscape: () => void }).onEscape();
          }

          if (backdrop?.element) {
            backdrop.element.remove();
            backdrop.destroy();
          }

          if (component?.element) {
            component.element.remove();
            component.destroy();
          }

          return true;
        }

        return (
          component?.ref as { onKeyDown: (props: SuggestionProps) => boolean }
        )?.onKeyDown(props);
      },

      onExit(props: SuggestionProps) {
        props.editor
          .chain()
          .setMeta("hideDragHandle", false)
          .setMeta("lockDragHandle", false)
          .run();

        if (!component) return

        if (backdrop.element && document.body.contains(backdrop.element)) {
          document.body.removeChild(backdrop.element);
        }

        backdrop.destroy()

        if (component.element && document.body.contains(component.element)) {
          document.body.removeChild(component.element);
        }

        component.destroy();
      },
    };
  },
};

export default suggestion;
