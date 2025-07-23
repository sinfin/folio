import type { Editor } from "@tiptap/core";
import type { FolioEditorBubbleMenuSource } from "@/components/tiptap-editors/folio-editor/folio-editor-bubble-menus";

import { TableAddColumnAfter } from "@/components/tiptap-icons/table-add-column-after";
import { TableAddColumnBefore } from "@/components/tiptap-icons/table-add-column-before";
import { TableAddRowAfter } from "@/components/tiptap-icons/table-add-row-after";
import { TableAddRowBefore } from "@/components/tiptap-icons/table-add-row-before";
import { TableDeleteColumn } from "@/components/tiptap-icons/table-delete-column";
import { TableDeleteRow } from "@/components/tiptap-icons/table-delete-row";
import { TableDeleteTable } from "@/components/tiptap-icons/table-delete-table";
import { TableMergeCells } from "@/components/tiptap-icons/table-merge-cells";
import { TableSplitCell } from "@/components/tiptap-icons/table-split-cell";
import { TableToggleHeaderCell } from "@/components/tiptap-icons/table-toggle-header-cell";
import { TableToggleHeaderColumn } from "@/components/tiptap-icons/table-toggle-header-column";
import { TableToggleHeaderRow } from "@/components/tiptap-icons/table-toggle-header-row";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addColumnAfter: "Přidat sloupec za",
    addColumnBefore: "Přidat sloupec před",
    addRowAfter: "Přidat řádek za",
    addRowBefore: "Přidat řádek před",
    deleteColumn: "Odstranit sloupec",
    deleteRow: "Odstranit řádek",
    deleteTable: "Odstranit tabulku",
    mergeCells: "Sloučit buňky",
    splitCell: "Rozdělit buňku",
    toggleHeaderCell: "Přepnout buňku na záhlaví",
    toggleHeaderColumn: "Přepnout sloupec na záhlaví",
    toggleHeaderRow: "Přepnout řádek na záhlaví",
  },
  en: {
    addColumnAfter: "Add column after",
    addColumnBefore: "Add column before",
    addRowAfter: "Add row after",
    addRowBefore: "Add row before",
    deleteColumn: "Remove column",
    deleteRow: "Remove row",
    deleteTable: "Remove table",
    mergeCells: "Merge cells",
    splitCell: "Split cell",
    toggleHeaderCell: "Toggle cell header",
    toggleHeaderColumn: "Toggle column header",
    toggleHeaderRow: "Toggle row header",
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
        icon: TableAddColumnBefore,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addColumnBefore().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "addColumnAfter"),
        icon: TableAddColumnAfter,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addColumnAfter().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "deleteColumn"),
        icon: TableDeleteColumn,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteColumn().run();
        },
      },
    ],
    [
      {
        title: translate(TRANSLATIONS, "addRowBefore"),
        icon: TableAddRowBefore,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addRowBefore().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "addRowAfter"),
        icon: TableAddRowAfter,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addRowAfter().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "deleteRow"),
        icon: TableDeleteRow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteRow().run();
        },
      },
    ],
    [
      {
        title: translate(TRANSLATIONS, "toggleHeaderColumn"),
        icon: TableToggleHeaderColumn,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderColumn().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "toggleHeaderRow"),
        icon: TableToggleHeaderRow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderRow().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "toggleHeaderCell"),
        icon: TableToggleHeaderCell,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderCell().run();
        },
      },
    ],
    [
      {
        title: translate(TRANSLATIONS, "mergeCells"),
        icon: TableMergeCells,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().mergeCells().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "splitCell"),
        icon: TableSplitCell,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().splitCell().run();
        },
      },
      {
        title: translate(TRANSLATIONS, "deleteTable"),
        icon: TableDeleteTable,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteTable().run();
        },
      },
    ]
  ],
};
