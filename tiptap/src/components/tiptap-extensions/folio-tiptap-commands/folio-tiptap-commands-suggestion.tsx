import { computePosition, flip, offset, size } from "@floating-ui/dom";
import { ReactRenderer } from "@tiptap/react";
import { Editor } from "@tiptap/core";
import type { Range } from "@tiptap/core";

import { Pilcrow } from "lucide-react";

import {
  FolioTiptapCommandsList,
} from "./folio-tiptap-commands-list";
import { FolioTiptapCommandsListBackdrop } from "./folio-tiptap-commands-list-backdrop";

import { markIcons } from "@/components/tiptap-ui/mark-button/mark-button";

import { ListsCommandGroup } from '@/components/tiptap-command-groups';

export const normalizeString = (string: string) =>
  string
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase();

interface SuggestionProps {
  editor: Editor;
  range: Range;
  clientRect: () => DOMRect;
  command: (item: FolioEditorCommandForSuggestion) => void;
  items: FolioEditorCommandGroupForSuggestion[];
  query: string;
  event: KeyboardEvent;
}

export const makeFolioTiptapCommandsSuggestionItems = (groups: FolioEditorCommandGroup[]) => {
  return ({ query }: { editor: Editor; query: string }) => {
    const normalizedQuery = normalizeString(query);

    return translateAndNormalizeTitles(groups)
      .map((group: FolioEditorCommandGroupForSuggestion): FolioEditorCommandGroupForSuggestion | null => {
        const matchingCommands = group.commandsForSuggestion.filter((commandForSuggestion: FolioEditorCommandForSuggestion) => {
          return commandForSuggestion.normalizedTitle.indexOf(normalizedQuery) !== -1;
        });

        if (matchingCommands.length > 0) {
          return { ...group, commandsForSuggestion: matchingCommands };
        }

        return null;
      })
      .filter((group): group is FolioEditorCommandGroupForSuggestion => group !== null);
  };
};

const translateAndNormalizeTitles = (
  groups: FolioEditorCommandGroup[],
): FolioEditorCommandGroupForSuggestion[] => {
  const lang = document.documentElement.lang as "cs" | "en";
  return groups.map((group: FolioEditorCommandGroup) => {
    let groupTitle;

    if (typeof group.title === "string") {
      groupTitle = group.title;
    } else {
      groupTitle = group.title[lang] || group.title.en;
    }

    return {
      title: groupTitle,
      key: group.key,
      commandsForSuggestion: group.commands.map((command: FolioEditorCommand) => {
        let itemTitle;

        if (typeof command.title === "string") {
          itemTitle = command.title;
        } else {
          itemTitle = command.title[lang] || command.title.en;
        }

        return {
          ...command,
          title: itemTitle,
          normalizedTitle: normalizeString(itemTitle),
        };
      }),
    } as FolioEditorCommandGroupForSuggestion;
  });
};

export const folioTiptapCommandsSuggestionWithoutItems = {
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
        middleware: [flip(), offset(12), size({
          apply( { availableWidth, availableHeight, elements }) {
            Object.assign((component!.element as HTMLElement).style, {
              maxWidth: `${Math.max(0, availableWidth)}px`,
              maxHeight: `${Math.max(0, availableHeight)}px`,
              pointerEvents: "none",
            });
          },
        })],
      }).then((pos) => {
        (component!.element as HTMLElement).dataset.placement = pos.placement;
        Object.assign((component!.element as HTMLElement).style, {
          left: `${pos.x}px`,
          top: `${pos.y}px`,
          zIndex: "11",
          position: pos.strategy === "fixed" ? "fixed" : "absolute",
          display: "flex",
          flexDirection: "column"
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

        backdrop = new ReactRenderer(FolioTiptapCommandsListBackdrop, {
          props: { ...props, query: props.query },
          editor: props.editor,
        });
        document.body.appendChild(backdrop.element);

        component = new ReactRenderer(FolioTiptapCommandsList, {
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
}

export const makeFolioTiptapCommandsSuggestion = ({ textStylesCommandGroup }: { textStylesCommandGroup: FolioEditorCommandGroup }) => {
  return ({
    ...folioTiptapCommandsSuggestionWithoutItems,
    items: makeFolioTiptapCommandsSuggestionItems([ textStylesCommandGroup, ListsCommandGroup ]),
  })
};

export default makeFolioTiptapCommandsSuggestion;
