import type { Editor } from '@tiptap/core';
import type { FolioEditorBubbleMenuSource } from '@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus';

import { FolioTiptapPagesNode } from './folio-tiptap-pages-node';
import { PaginatedPlusAfterIcon, PaginatedPlusBeforeIcon } from '@/components/tiptap-icons';
import { X } from 'lucide-react';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addFolioTiptapPageBefore: "Přidat stránku před",
    addFolioTiptapPageAfter: "Přidat stránku za",
    deleteFolioTiptapPage: "Odstranit stránku",
  },
  en: {
    addFolioTiptapPageBefore: "Add page before",
    addFolioTiptapPageAfter: "Add page after",
    deleteFolioTiptapPage: "Remove page",
  }
}

export const FOLIO_TIPTAP_PAGES_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource = {
  pluginKey: "folioTiptapPagesBubbleMenu",
  shouldShow: ({ editor, state }) => {
    return editor.isActive(FolioTiptapPagesNode.name)
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
        key: "deleteFolioTiptapPage",
        title: translate(TRANSLATIONS, "deleteFolioTiptapPage"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteFolioTiptapPage().run()
        }
      },
      {
        key: "addFolioTiptapPageAfter",
        title: translate(TRANSLATIONS, "addFolioTiptapPageAfter"),
        icon: PaginatedPlusAfterIcon,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addFolioTiptapPageAfter().run()
        }
      },
    ]
  ]
}
