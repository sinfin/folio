import type { Editor } from "@tiptap/core";
import type { FolioEditorBubbleMenuSource } from "@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus";

import { X } from "lucide-react";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addColumnBefore: "Přidat sloupec před",
    addColumnAfter: "Přidat sloupec za",
    deleteColumn: "Odstranit sloupec",
    addRowBefore: "Přidat řádek před",
    addRowAfter: "Přidat řádek za",
    deleteRow: "Odstranit řádek",
    deleteTable: "Odstranit tabulku",
    mergeCells: "Sloučit buňky",
    splitCell: "Rozdělit buňku",
    toggleHeaderColumn: "Přepnout sloupec na záhlaví",
    toggleHeaderRow: "Přepnout řádek na záhlaví",
    toggleHeaderCell: "Přepnout buňku na záhlaví",
  },
  en: {
    addColumnBefore: "Add column before",
    addColumnAfter: "Add column after",
    deleteColumn: "Remove column",
    addRowBefore: "Add row before",
    addRowAfter: "Add row after",
    deleteRow: "Remove row",
    deleteTable: "Remove table",
    mergeCells: "Merge cells",
    splitCell: "Split cell",
    toggleHeaderColumn: "Toggle column header",
    toggleHeaderRow: "Toggle row header",
    toggleHeaderCell: "Toggle cell header",
  },
};

export const TABLE_BUBBLE_MENU_SOURCE: FolioEditorBubbleMenuSource = {
  pluginKey: "tableBubbleMenu",
  shouldShow: ({ editor, view, state, oldState, from, to }) => {
    return editor.isActive("table");
  },
  items: [
    [
      {
        title: translate(TRANSLATIONS, "addColumnBefore"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addColumnBefore().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "addColumnAfter"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addColumnAfter().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "toggleHeaderColumn"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderColumn().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "deleteColumn"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteColumn().run();
        },
      },
    ],
    [
      {
        title: translate(TRANSLATIONS, "addRowBefore"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addRowBefore().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "addRowAfter"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addRowAfter().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "toggleHeaderRow"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderRow().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "deleteRow"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteRow().run();
        },
      },
    ],
    [
      {
        title: translate(TRANSLATIONS, "mergeCells"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().mergeCells().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "splitCell"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().splitCell().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "toggleHeaderCell"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderCell().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "deleteTable"),
        icon: X,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteTable().run();
        },
      },
    ]
  ],
};
