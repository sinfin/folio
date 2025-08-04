import React from "react";
import { BubbleMenu } from "@tiptap/react/menus";

import { type EditorState } from "@tiptap/pm/state";
import type { Editor } from "@tiptap/core";

import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import { FOLIO_TIPTAP_COLUMNS_BUBBLE_MENU_SOURCE } from "@/components/tiptap-extensions/folio-tiptap-columns/folio-tiptap-columns-bubble-menu-source";
import { TABLE_BUBBLE_MENU_SOURCE } from '@/lib/table-bubble-menu-source';
import { FOLIO_TIPTAP_FLOAT_BUBBLE_MENU_SOURCE } from '@/components/tiptap-extensions/folio-tiptap-float';

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

export interface FolioEditorBubbleMenuSource {
  pluginKey: string;
  shouldShow: (params: FolioEditorBubbleMenuSourceShouldShowArgs) => boolean;
  items: FolioEditorBubbleMenuSourceItem[][];
  activeKeys?: (params: FolioEditorBubbleMenuSourceShouldShowArgs) => string[];
  disabledKeys?: (params: FolioEditorBubbleMenuSourceShouldShowArgs) => string[];
  placement?: "top" | "right" | "bottom" | "left" | "top-start" | "top-end" | "right-start" | "right-end" | "bottom-start" | "bottom-end" | "left-start" | "left-end" | undefined;
}

export function FolioEditorBubbleMenu({
  editor,
  source,
}: {
  editor: Editor;
  source: FolioEditorBubbleMenuSource;
}) {
  const floatingUiOptions = {
    placement: source.placement || "bottom",
    offset: 12,
    flip: true,
  }

  const [activeKeys, setActiveKeys] = React.useState<string[]>([])
  const [disabledKeys, setDisabledKeys] = React.useState<string[]>([])

  return (
    <BubbleMenu
      pluginKey={source.pluginKey}
      shouldShow={({ editor, state }: FolioEditorBubbleMenuSourceShouldShowArgs) => {
        const show = source.shouldShow({ editor, state })

        if (show) {
          if (source.activeKeys) {
            const newActiveKeys = source.activeKeys({ editor, state })

            if (JSON.stringify(newActiveKeys) !== JSON.stringify(activeKeys)) {
              setActiveKeys(newActiveKeys)
            }
          }

          if (source.disabledKeys) {
            const newDisabledKeys = source.disabledKeys({ editor, state })

            if (JSON.stringify(newDisabledKeys) !== JSON.stringify(disabledKeys)) {
              setDisabledKeys(newDisabledKeys)
            }
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

export function FolioEditorBubbleMenus({
  editor,
  blockEditor,
}: FolioEditorBubbleMenusProps) {
  if (!editor) return null;

  return (
    <>
      {blockEditor && (
        <FolioEditorBubbleMenu
          editor={editor}
          source={FOLIO_TIPTAP_COLUMNS_BUBBLE_MENU_SOURCE}
        />
      )}

      {blockEditor && (
        <FolioEditorBubbleMenu
          editor={editor}
          source={TABLE_BUBBLE_MENU_SOURCE}
        />
      )}

      {blockEditor && (
        <FolioEditorBubbleMenu
          editor={editor}
          source={FOLIO_TIPTAP_FLOAT_BUBBLE_MENU_SOURCE}
        />
      )}
    </>
  );
}
