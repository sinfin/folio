import type { Editor } from '@tiptap/core';
import type { FolioEditorBubbleMenuSource } from '@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus';

import { FolioTiptapFloatNode } from './folio-tiptap-float-node';
import { AlignJustify, ArrowUpWideNarrow, ArrowDownWideNarrow, ArrowLeftToLine, ArrowRightToLine, X } from 'lucide-react';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    setFloatSideToLeft: "Obtékaný obsah - vlevo",
    setFloatSideToRight: "Obtékaný obsah - vpravo",
    cancelFloat: "Zrušit obtékání obsahu",
    setFloatSizeToSmall: "Obtékaný obsah - úzký",
    setFloatSizeToMedium: "Obtékaný obsah - střední",
    setFloatSizeToLarge: "Obtékaný obsah - široký",
  },
  en: {
    setFloatSideToLeft: "Float content - left",
    setFloatSideToRight: "Float content - right",
    cancelFloat: "Cancel float content",
    setFloatSizeToSmall: "Float content - small",
    setFloatSizeToMedium: "Float content - medium",
    setFloatSizeToLarge: "Float content - large",
  }
}

export const FOLIO_TIPTAP_FLOAT_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource = {
  pluginKey: "folioTiptapFloatBubbleMenu",
  shouldShow: ({ editor, view, state, oldState, from, to }) => {
    return editor.isActive(FolioTiptapFloatNode.name)
  },
  items: [
    [
      {
        title: translate(TRANSLATIONS, "setFloatSideToLeft"),
        icon: ArrowLeftToLine,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ side: "left" }).run()
        }
      },
      {
        title: translate(TRANSLATIONS, "cancelFloat"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().cancelFolioTiptapFloat().run()
        }
      },
      {
        title: translate(TRANSLATIONS, "setFloatSideToRight"),
        icon: ArrowRightToLine,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ side: "right" }).run()
        }
      },
    ],
    [
      {
        title: translate(TRANSLATIONS, "setFloatSizeToSmall"),
        icon: ArrowDownWideNarrow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ size: "small" }).run()
        }
      },
      {
        title: translate(TRANSLATIONS, "setFloatSizeToMedium"),
        icon: AlignJustify,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ size: "medium" }).run()
        }
      },
      {
        title: translate(TRANSLATIONS, "setFloatSizeToLarge"),
        icon: ArrowUpWideNarrow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ size: "large" }).run()
        }
      }
    ]
  ]
}
