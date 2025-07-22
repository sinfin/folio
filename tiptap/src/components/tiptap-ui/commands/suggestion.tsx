import { computePosition, flip, offset } from "@floating-ui/dom";
import { ReactRenderer } from "@tiptap/react";
import { Editor } from "@tiptap/core";
import type { Range } from "@tiptap/core";

import { Pilcrow } from "lucide-react";

import {
  CommandsList,
  type CommandItem,
  type CommandGroup,
  type UntranslatedCommandGroup,
  type UntranslatedCommandItem,
} from "./commands-list";
import { CommandsListBackdrop } from "./commands-list-backdrop";

import { markIcons } from "@/components/tiptap-ui/mark-button/mark-button";

import { FolioTiptapColumnsCommandItem } from "@/components/tiptap-extensions/folio-tiptap-columns";

import {
  LIST_TRANSLATIONS,
  listIcons,
} from "@/components/tiptap-ui/list-button/list-button";

export const normalizeString = (string: string) =>
  string
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase();

interface SuggestionProps {
  editor: Editor;
  range: Range;
  clientRect: () => DOMRect;
  command: (item: CommandItem) => void;
  items: CommandGroup[];
  query: string;
  event: KeyboardEvent;
}

export const makeSuggestionItems = (groups: UntranslatedCommandGroup[]) => {
  return ({ query }: { editor: Editor; query: string }) => {
    const normalizedQuery = normalizeString(query);

    return translateAndNormalizeTitles(groups)
      .map((group: CommandGroup): CommandGroup | null => {
        const matchingItems = group.items.filter((item: CommandItem) => {
          return item.normalizedTitle.indexOf(normalizedQuery) !== -1;
        });
        if (matchingItems.length > 0) {
          return { ...group, items: matchingItems };
        }
        return null;
      })
      .filter((group): group is CommandGroup => group !== null);
  };
};

export const defaultGroupForRichText: UntranslatedCommandGroup = {
  title: { cs: "Text", en: "Text" },
  items: [
    {
      title: {
        cs: LIST_TRANSLATIONS["cs"]["bulletList"],
        en: LIST_TRANSLATIONS["en"]["bulletList"],
      },
      icon: listIcons["bulletList"],
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor.chain().focus().deleteRange(range).toggleBulletList().run();
      },
    },
    {
      title: {
        cs: LIST_TRANSLATIONS["cs"]["orderedList"],
        en: LIST_TRANSLATIONS["en"]["orderedList"],
      },
      icon: listIcons["orderedList"],
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor.chain().focus().deleteRange(range).toggleOrderedList().run();
      },
    },
  ],
};

export const defaultGroupForBlock: UntranslatedCommandGroup = {
  ...defaultGroupForRichText,
  items: [...defaultGroupForRichText.items, FolioTiptapColumnsCommandItem],
};

const translateAndNormalizeTitles = (
  groups: UntranslatedCommandGroup[],
): CommandGroup[] => {
  const lang = document.documentElement.lang as "cs" | "en";
  return groups.map((group: UntranslatedCommandGroup) => {
    let groupTitle;

    if (typeof group.title === "string") {
      groupTitle = group.title;
    } else {
      groupTitle = group.title[lang] || group.title.en;
    }

    return {
      ...group,
      title: groupTitle,
      items: group.items.map((item: UntranslatedCommandItem) => {
        let itemTitle;

        if (typeof item.title === "string") {
          itemTitle = item.title;
        } else {
          itemTitle = item.title[lang] || item.title.en;
        }

        return {
          ...item,
          title: itemTitle,
          normalizedTitle: normalizeString(itemTitle),
        };
      }),
    };
  });
};

export const suggestion = {
  items: makeSuggestionItems([defaultGroupForRichText]),

  allowSpaces: false,

  render: () => {
    let component: ReactRenderer | null = null;
    let backdrop: ReactRenderer | null = null;

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
        });
        document.body.appendChild(backdrop.element);

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

        if (!component) return;

        if (backdrop) {
          if (backdrop.element && document.body.contains(backdrop.element)) {
            document.body.removeChild(backdrop.element);
          }

          backdrop.destroy();
        }

        if (component.element && document.body.contains(component.element)) {
          document.body.removeChild(component.element);
        }

        component.destroy();
      },
    };
  },
};

export default suggestion;
