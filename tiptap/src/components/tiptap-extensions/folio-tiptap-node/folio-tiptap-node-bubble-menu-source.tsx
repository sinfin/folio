import { findParentNode } from "@tiptap/core";
import { Node } from "@tiptap/pm/model";
import type { Editor } from '@tiptap/core';
import type { FolioEditorBubbleMenuSource } from '@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus';

import { FolioTiptapNodeExtension } from './folio-tiptap-node-extension';
import {
  ArrowDownIcon,
  ArrowUpIcon,
  CloseIcon,
  EditIcon,
} from '@/components/tiptap-icons';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    moveFolioTiptapNodeUp: "Posunout nahoru",
    moveFolioTiptapNodeDown: "Posunout dolů",
    editFolioTipapNode: "Upravit",
    removeFolioTiptapNode: "Odstranit",
  },
  en: {
    moveFolioTiptapNodeUp: "Move up",
    moveFolioTiptapNodeDown: "Move down",
    editFolioTipapNode: "Edit",
    removeFolioTiptapNode: "Remove",
  }
}

export const FOLIO_TIPTAP_NODE_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource = {
  pluginKey: "folioTiptapNodeBubbleMenu",
  priority: 1,
  offset: ({rects}) => -rects.reference.height / 2 - rects.floating.height / 2,
  shouldShow: ({ editor, state }) => {
    return editor.isActive(FolioTiptapNodeExtension.name)
  },
  disabledKeys: ({ state }) => {
    const result = []

    if (!state.doc.resolve(state.selection.from).nodeBefore) {
      result.push("moveFolioTiptapNodeUp");
    }

    if (!state.doc.resolve(state.selection.to).nodeAfter) {
      result.push("moveFolioTiptapNodeDown");
    }

    return result
  },
  items: [
    [
      {
        key: "moveFolioTiptapNodeUp",
        title: translate(TRANSLATIONS, "moveFolioTiptapNodeUp"),
        icon: ArrowUpIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().moveFolioTiptapNodeUp().run()
        }
      },
      {
        key: "moveFolioTiptapNodeDown",
        title: translate(TRANSLATIONS, "moveFolioTiptapNodeDown"),
        icon: ArrowDownIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().moveFolioTiptapNodeDown().run()
        }
      },
      {
        key: "editFolioTipapNode",
        title: translate(TRANSLATIONS, "editFolioTipapNode"),
        icon: EditIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().editFolioTipapNode().run()
        }
      },
      {
        key: "removeFolioTiptapNode",
        title: translate(TRANSLATIONS, "removeFolioTiptapNode"),
        icon: CloseIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().removeFolioTiptapNode().run()
        }
      },
    ]
  ]
}
