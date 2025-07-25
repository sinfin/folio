import { findParentNode } from "@tiptap/core";
import { Node } from "@tiptap/pm/model";
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
  shouldShow: ({ editor, state }) => {
    return editor.isActive(FolioTiptapFloatNode.name)
  },
  activeKeys: ({ editor }) => {
    const floatNode = findParentNode((node: Node) => node.type.name === FolioTiptapFloatNode.name)(editor.state.selection);
    if (!floatNode) return []

    const result = []

    if (floatNode.node.attrs.side === "right") {
      result.push("setFloatSideToRight")
    } else {
      result.push("setFloatSideToLeft")
    }

    if (floatNode.node.attrs.size === "small") {
      result.push("setFloatSizeToSmall")
    } else if (floatNode.node.attrs.size === "large") {
      result.push("setFloatSizeToLarge")
    } else {
      result.push("setFloatSizeToMedium")
    }

    return result
  },
  items: [
    [
      {
        key: "setFloatSideToLeft",
        title: translate(TRANSLATIONS, "setFloatSideToLeft"),
        icon: ArrowLeftToLine,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ side: "left" }).run()
        }
      },
      {
        key: "cancelFloat",
        title: translate(TRANSLATIONS, "cancelFloat"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().cancelFolioTiptapFloat().run()
        }
      },
      {
        key: "setFloatSideToRight",
        title: translate(TRANSLATIONS, "setFloatSideToRight"),
        icon: ArrowRightToLine,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ side: "right" }).run()
        }
      },
    ],
    [
      {
        key: "setFloatSizeToSmall",
        title: translate(TRANSLATIONS, "setFloatSizeToSmall"),
        icon: ArrowDownWideNarrow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ size: "small" }).run()
        }
      },
      {
        key: "setFloatSizeToMedium",
        title: translate(TRANSLATIONS, "setFloatSizeToMedium"),
        icon: AlignJustify,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ size: "medium" }).run()
        }
      },
      {
        key: "setFloatSizeToLarge",
        title: translate(TRANSLATIONS, "setFloatSizeToLarge"),
        icon: ArrowUpWideNarrow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().setFolioTiptapFloatAttributes({ size: "large" }).run()
        }
      }
    ]
  ]
}
