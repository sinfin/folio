import type { Editor } from '@tiptap/core';
import type { FolioEditorBubbleMenuSource } from '@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus';

import { FolioTiptapPagesNode } from './folio-tiptap-pages-node';
import {
  PaginatedPlusAfterIcon,
  PaginatedPlusBeforeIcon,
  ArrowUpIcon,
  ArrowDownIcon
} from '@/components/tiptap-icons';
import { X } from 'lucide-react';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addFolioTiptapPageBefore: "Přidat stránku před",
    moveFolioTiptapPageUp: "Posunout stránku nahoru",
    addFolioTiptapPageAfter: "Přidat stránku za",
    moveFolioTiptapPageDown: "Posunout stránku dolů",
    deleteFolioTiptapPage: "Odstranit stránku",
  },
  en: {
    addFolioTiptapPageBefore: "Add page before",
    moveFolioTiptapPageUp: "Move page up",
    addFolioTiptapPageAfter: "Add page after",
    moveFolioTiptapPageDown: "Move page down",
    deleteFolioTiptapPage: "Remove page",
  }
}

export const FOLIO_TIPTAP_PAGES_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource = {
  pluginKey: "folioTiptapPagesBubbleMenu",
  priority: 1,
  shouldShow: ({ editor }) => {
    return editor.isActive(FolioTiptapPagesNode.name)
  },
  disabledKeys: ({ editor }) => {
    const result = []

    if (!editor.can().moveFolioTiptapPageUp()) {
      result.push("moveFolioTiptapPageUp");
    }

    if (!editor.can().moveFolioTiptapPageDown()) {
      result.push("moveFolioTiptapPageDown");
    }

    return result
  },
  items: [
    [
      {
        key: "addFolioTiptapPageBefore",
        title: translate(TRANSLATIONS, "addFolioTiptapPageBefore"),
        icon: PaginatedPlusBeforeIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addFolioTiptapPageBefore().run()
        }
      },
      {
        key: "moveFolioTiptapPageUp",
        title: translate(TRANSLATIONS, "moveFolioTiptapPageUp"),
        icon: ArrowUpIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().moveFolioTiptapPageUp().run()
        }
      },
    ], [
      {
        key: "addFolioTiptapPageAfter",
        title: translate(TRANSLATIONS, "addFolioTiptapPageAfter"),
        icon: PaginatedPlusAfterIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addFolioTiptapPageAfter().run()
        }
      },
      {
        key: "moveFolioTiptapPageDown",
        title: translate(TRANSLATIONS, "moveFolioTiptapPageDown"),
        icon: ArrowDownIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().moveFolioTiptapPageDown().run()
        }
      },
    ], [
      {
        key: "deleteFolioTiptapPage",
        title: translate(TRANSLATIONS, "deleteFolioTiptapPage"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteFolioTiptapPage().run()
        }
      },
    ]
  ]
}
