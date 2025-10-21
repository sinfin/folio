import type { Editor } from "@tiptap/core";
import type { FolioEditorBubbleMenuSource } from "@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus";

import { FolioTiptapColumnsNode } from "./folio-tiptap-columns-node";
import { AddColumnAfter } from "@/components/tiptap-icons/add-column-after";
import { AddColumnBefore } from "@/components/tiptap-icons/add-column-before";
import { X } from "lucide-react";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addFolioTiptapColumnBefore: "Přidat sloupec před",
    addFolioTiptapColumnAfter: "Přidat sloupec za",
    deleteFolioTiptapColumn: "Odstranit sloupec",
  },
  en: {
    addFolioTiptapColumnBefore: "Add column before",
    addFolioTiptapColumnAfter: "Add column after",
    deleteFolioTiptapColumn: "Remove column",
  },
};

export const FOLIO_TIPTAP_COLUMNS_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource =
  {
    pluginKey: "folioTiptapColumnsBubbleMenu",
    priority: 1,
    shouldShow: ({ editor }) => {
      return editor.isActive(FolioTiptapColumnsNode.name);
    },
    items: [
      [
        {
          key: "addFolioTiptapColumnBefore",
          title: translate(TRANSLATIONS, "addFolioTiptapColumnBefore"),
          icon: AddColumnBefore,
          command: ({ editor }: { editor: Editor }) => {
            editor.chain().focus().addFolioTiptapColumnBefore().run();
          },
        },
        {
          key: "deleteFolioTiptapColumn",
          title: translate(TRANSLATIONS, "deleteFolioTiptapColumn"),
          icon: X,
          command: ({ editor }: { editor: Editor }) => {
            editor.chain().focus().deleteFolioTiptapColumn().run();
          },
        },
        {
          key: "addFolioTiptapColumnAfter",
          title: translate(TRANSLATIONS, "addFolioTiptapColumnAfter"),
          icon: AddColumnAfter,
          command: ({ editor }: { editor: Editor }) => {
            editor.chain().focus().addFolioTiptapColumnAfter().run();
          },
        },
      ],
    ],
  };
