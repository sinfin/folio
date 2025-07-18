import type { Editor } from '@tiptap/core';
import type { FolioEditorBubbleMenuSource } from '@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus';

import { FolioTiptapColumnsNode } from './folio-tiptap-columns-node';
import { AddColumnAfter } from '@/components/tiptap-icons/add-column-after';
import { AddColumnBefore } from '@/components/tiptap-icons/add-column-before';
import { X } from 'lucide-react';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addColumnBefore: "Přidat sloupec před",
    addColumnAfter: "Přidat sloupec za",
    removeColumn: "Odstranit sloupec",
  },
  en: {
    addColumnBefore: "Add column before",
    addColumnAfter: "Add column after",
    removeColumn: "Remove column",
  }
}

export const folioTiptapColumnsBubbleMenuSource: FolioEditorBubbleMenuSource = {
  pluginKey: "folioTiptapColumnsBubbleMenu",
  shouldShow: ({ editor, view, state, oldState, from, to }) => {
    return editor.isActive(FolioTiptapColumnsNode.name)
  },
  items: [
    {
      title: translate(TRANSLATIONS, "addColumnBefore"),
      icon: AddColumnBefore,
      command: ({ editor }: { editor: Editor }) => {
        editor.chain().focus().addColumnBefore().run()
      }
    },
    {
      title: translate(TRANSLATIONS, "addColumnAfter"),
      icon: AddColumnAfter,
      command: ({ editor }: { editor: Editor }) => {
        editor.chain().focus().addColumnAfter().run()
      }
    },
    {
      title: translate(TRANSLATIONS, "removeColumn"),
      icon: X,
      command: ({ editor }: { editor: Editor }) => {
        editor.chain().focus().deleteColumn().run()
      }
    },
  ]
}
