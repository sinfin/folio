import React from "react";
import { BubbleMenu } from "@tiptap/react/menus";

import type { Editor } from "@tiptap/core";

import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import { FOLIO_TIPTAP_COLUMNS_BUBBLE_MENU_SOURCE } from "@/components/tiptap-extensions/folio-tiptap-columns/folio-tiptap-columns-bubble-menu-source";
import { TABLE_BUBBLE_MENU_SOURCE } from '@/lib/table-bubble-menu-source';
import { FOLIO_TIPTAP_FLOAT_LAYOUT_BUBBLE_MENU_SOURCE } from '@/components/tiptap-extensions/folio-tiptap-float-layout';

import "./folio-editor-bubble-menus.scss";

export interface FolioEditorBubbleMenusProps {
  editor: Editor;
  blockEditor: boolean;
}

export interface FolioEditorBubbleMenuSourceItem {
  command: (params: { editor: Editor }) => void;
  icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  title: string;
}

export interface FolioEditorBubbleMenuSource {
  pluginKey: string;
  shouldShow: (params: {
    editor: Editor;
    view: any;
    state: any;
    oldState?: any;
    from: number;
    to: number;
  }) => boolean;
  items: FolioEditorBubbleMenuSourceItem[][];
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

  return (
    <BubbleMenu
      pluginKey={source.pluginKey}
      shouldShow={source.shouldShow}
      options={floatingUiOptions}
      className="f-tiptap-editor-bubble-menu"
      data-bubble-menu-type={source.pluginKey}
    >
      {source.items.map((row, rowIndex) => (
        <div className="f-tiptap-editor-bubble-menu__row" key={rowIndex}>
          {row.map((item) => {
            const Icon = item.icon;

            return (
              <Button
                key={item.title}
                type="button"
                data-style="ghost"
                role="button"
                tabIndex={-1}
                aria-label={item.title}
                tooltip={item.title}
                onClick={() => {
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
          source={FOLIO_TIPTAP_FLOAT_LAYOUT_BUBBLE_MENU_SOURCE}
        />
      )}
    </>
  );
}
