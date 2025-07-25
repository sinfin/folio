import type { Editor } from '@tiptap/core';
import type { FolioEditorBubbleMenuSource } from '@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus';

import { FolioTiptapFloatLayoutNode } from './folio-tiptap-float-layout-node';
import { AlignJustify, ArrowUpWideNarrow, ArrowDownWideNarrow, ArrowLeftToLine, ArrowRightToLine } from 'lucide-react';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    setFloatSideToLeft: "Obtékaný obsah - vlevo",
    setFloatSideToRight: "Obtékaný obsah - vpravo",
    setFloatSizeToSmall: "Obtékaný obsah - úzký",
    setFloatSizeToMedium: "Obtékaný obsah - střední",
    setFloatSizeToLarge: "Obtékaný obsah - široký",
  },
  en: {
    setFloatSideToLeft: "Float content - left",
    setFloatSideToRight: "Float content - right",
    setFloatSizeToSmall: "Float content - small",
    setFloatSizeToMedium: "Float content - medium",
    setFloatSizeToLarge: "Float content - large",
  }
}

export const FOLIO_TIPTAP_FLOAT_LAYOUT_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource = {
  pluginKey: "folioTiptapFloatLayoutBubbleMenu",
  shouldShow: ({ editor, view, state, oldState, from, to }) => {
    return editor.isActive(FolioTiptapFloatLayoutNode.name)
  },
  items: [
    [
      {
        title: translate(TRANSLATIONS, "setFloatSideToLeft"),
        icon: ArrowLeftToLine,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFloatLayoutAttributes({ side: "left" }).run()
        }
      },
      {
        title: translate(TRANSLATIONS, "setFloatSideToRight"),
        icon: ArrowRightToLine,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFloatLayoutAttributes({ side: "right" }).run()
        }
      },
      {
        title: translate(TRANSLATIONS, "setFloatSizeToSmall"),
        icon: ArrowDownWideNarrow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFloatLayoutAttributes({ size: "small" }).run()
        }
      },
      {
        title: translate(TRANSLATIONS, "setFloatSizeToMedium"),
        icon: AlignJustify,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFloatLayoutAttributes({ size: "medium" }).run()
        }
      },
      {
        title: translate(TRANSLATIONS, "setFloatSizeToLarge"),
        icon: ArrowUpWideNarrow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFloatLayoutAttributes({ size: "large" }).run()
        }
      }
    ]
  ]
}
