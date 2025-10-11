import React from "react";
import { BubbleMenu } from "@tiptap/react/menus";

import { type EditorState } from "@tiptap/pm/state";
import type { Editor } from "@tiptap/core";

import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import { FOLIO_TIPTAP_COLUMNS_BUBBLE_MENU_SOURCE } from "@/components/tiptap-extensions/folio-tiptap-columns/folio-tiptap-columns-bubble-menu-source";
import { TABLE_BUBBLE_MENU_SOURCE } from '@/lib/table-bubble-menu-source';
import { FOLIO_TIPTAP_FLOAT_BUBBLE_MENU_SOURCE } from '@/components/tiptap-extensions/folio-tiptap-float';
import { FOLIO_TIPTAP_NODE_BUBBLE_MENU_SOURCE } from '@/components/tiptap-extensions/folio-tiptap-node';
import { FOLIO_TIPTAP_PAGES_BUBBLE_MENU_SOURCE } from '@/components/tiptap-extensions/folio-tiptap-pages';

import "./folio-editor-bubble-menus.scss";

export interface FolioEditorBubbleMenusProps {
  editor: Editor;
  blockEditor: boolean;
}

export interface FolioEditorBubbleMenuSourceItem {
  command: (params: { editor: Editor }) => void;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  title: string;
  key: string;
}

export interface FolioEditorBubbleMenuSourceShouldShowArgs {
  editor: Editor;
  state: EditorState;
}

export interface FolioEditorBubbleMenuSourceOffsetArgs {
  rects: {
    reference: {
      height: number;
    }
    floating: {
      height: number;
    }
  }
}

export interface FolioEditorBubbleMenuSource {
  pluginKey: string;
  priority: number;
  shouldShow: (params: FolioEditorBubbleMenuSourceShouldShowArgs) => boolean;
  items: FolioEditorBubbleMenuSourceItem[][];
  activeKeys?: (params: FolioEditorBubbleMenuSourceShouldShowArgs) => string[];
  disabledKeys?: (params: FolioEditorBubbleMenuSourceShouldShowArgs) => string[];
  offset?: (params: FolioEditorBubbleMenuSourceOffsetArgs) => number;
  placement?: "top" | "right" | "bottom" | "left" | "top-start" | "top-end" | "right-start" | "right-end" | "bottom-start" | "bottom-end" | "left-start" | "left-end" | undefined;
}

export function FolioEditorBubbleMenu({
  editor,
  source,
  activeMenusRef,
}: {
  editor: Editor;
  source: FolioEditorBubbleMenuSource;
  activeMenusRef: React.MutableRefObject<Map<string, number>>;
}) {
  const floatingUiOptions = {
    placement: source.placement || "bottom",
    offset: source.offset || 12,
    flip: true,
  }

  const [activeKeys, setActiveKeys] = React.useState<string[]>([])
  const [disabledKeys, setDisabledKeys] = React.useState<string[]>([])

  const registerMenu = (sourceKey, priority) => {
    activeMenusRef.current.set(sourceKey, priority)
  }

  // Helper to unregister a menu
  const unregisterMenu = (sourceKey) => {
    activeMenusRef.current.delete(sourceKey)
  }

  const hasHighestPriority = (sourceKey, sourcePriority) => {
    if (activeMenusRef.current.size === 0) return false
    if (!activeMenusRef.current.has(sourceKey)) return false

    let highestPriority = -Infinity
    for (const [id, priority] of activeMenusRef.current.entries()) {
      if (priority > highestPriority) {
        highestPriority = priority
      }
    }

    return sourcePriority >= highestPriority
  }

  return (
    <BubbleMenu
      pluginKey={source.pluginKey}
      shouldShow={({ editor, state }: FolioEditorBubbleMenuSourceShouldShowArgs) => {
        const wantsToShow = source.shouldShow({ editor, state })
        let show = false

        if (wantsToShow) {
          registerMenu(source.pluginKey, source.priority)
          show = hasHighestPriority(source.pluginKey, source.priority)
        } else {
          unregisterMenu(source.pluginKey)
        }

        if (show) {
          if (source.activeKeys) {
            const newActiveKeys = source.activeKeys({ editor, state })
            setActiveKeys(newActiveKeys)
          }

          if (source.disabledKeys) {
            const newDisabledKeys = source.disabledKeys({ editor, state })
            setDisabledKeys(newDisabledKeys)
          }
        }

        return show
      }}
      options={floatingUiOptions}
      className="f-tiptap-editor-bubble-menu"
      data-bubble-menu-type={source.pluginKey}
    >
      {source.items.map((row, rowIndex) => (
        <div className="f-tiptap-editor-bubble-menu__row" key={rowIndex}>
          {row.map((item) => {
            const Icon = item.icon;
            const active = activeKeys.indexOf(item.key) !== -1;
            const disabled = disabledKeys.indexOf(item.key) !== -1;

            return (
              <Button
                key={item.title}
                type="button"
                data-style="ghost"
                data-size="large-icon"
                role="button"
                tabIndex={-1}
                aria-label={item.title}
                disabled={disabled}
                data-active-state={active ? "on" : "off"}
                aria-pressed={active}
                tooltip={item.title}
                onClick={disabled ? undefined : () => {
                  item.command({ editor });
                }}
              >
                <Icon className="tiptap-button-icon" />
              </Button>
            );
          })}
        </div>
      ))}
    </BubbleMenu>
  );
}

const BUBBLE_MENU_SOURCES = [
  FOLIO_TIPTAP_COLUMNS_BUBBLE_MENU_SOURCE,
  TABLE_BUBBLE_MENU_SOURCE,
  FOLIO_TIPTAP_FLOAT_BUBBLE_MENU_SOURCE,
  FOLIO_TIPTAP_NODE_BUBBLE_MENU_SOURCE,
  FOLIO_TIPTAP_PAGES_BUBBLE_MENU_SOURCE,
]

export function FolioEditorBubbleMenus({
  editor,
  blockEditor,
}: FolioEditorBubbleMenusProps) {
  if (!editor) return null;
  if (!blockEditor) return null;

  const activeMenusRef = React.useRef(new Map())

  return (
    <>
      {BUBBLE_MENU_SOURCES.map((source) => (
        <FolioEditorBubbleMenu
          editor={editor}
          source={source}
          key={source.pluginKey}
          activeMenusRef={activeMenusRef}
        />
      ))}
    </>
  );
}
