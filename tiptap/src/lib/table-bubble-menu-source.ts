import { findParentNode } from "@tiptap/core";
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
    addRowAfter: "Přidat řádek pod",
    addRowBefore: "Přidat řádek nad",
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
    addRowAfter: "Add row below",
    addRowBefore: "Add row above",
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
  shouldShow: ({ editor, state }) => {
    return editor.isActive("table");
  },
  disabledKeys: ({ editor }) => {
    const result = []

    if (!editor.can().splitCell()) {
      result.push("splitCell");
    }

    if (!editor.can().mergeCells()) {
      result.push("mergeCells");
    }

    return result
  },
  items: [
    [
      {
        key: "addColumnBefore",
        title: translate(TRANSLATIONS, "addColumnBefore"),
        icon: TableAddColumnBefore,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addColumnBefore().run();
        },
      },
      {
        key: "addColumnAfter",
        title: translate(TRANSLATIONS, "addColumnAfter"),
        icon: TableAddColumnAfter,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addColumnAfter().run();
        },
      },
      {
        key: "deleteColumn",
        title: translate(TRANSLATIONS, "deleteColumn"),
        icon: TableDeleteColumn,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteColumn().run();
        },
      },
    ],
    [
      {
        key: "addRowBefore",
        title: translate(TRANSLATIONS, "addRowBefore"),
        icon: TableAddRowBefore,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addRowBefore().run();
        },
      },
      {
        key: "addRowAfter",
        title: translate(TRANSLATIONS, "addRowAfter"),
        icon: TableAddRowAfter,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().addRowAfter().run();
        },
      },
      {
        key: "deleteRow",
        title: translate(TRANSLATIONS, "deleteRow"),
        icon: TableDeleteRow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteRow().run();
        },
      },
    ],
    [
      {
        key: "toggleHeaderColumn",
        title: translate(TRANSLATIONS, "toggleHeaderColumn"),
        icon: TableToggleHeaderColumn,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderColumn().run();
        },
      },
      {
        key: "toggleHeaderRow",
        title: translate(TRANSLATIONS, "toggleHeaderRow"),
        icon: TableToggleHeaderRow,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderRow().run();
        },
      },
      {
        key: "toggleHeaderCell",
        title: translate(TRANSLATIONS, "toggleHeaderCell"),
        icon: TableToggleHeaderCell,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().toggleHeaderCell().run();
        },
      },
    ],
    [
      {
        key: "mergeCells",
        title: translate(TRANSLATIONS, "mergeCells"),
        icon: TableMergeCells,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().mergeCells().run();
        },
      },
      {
        key: "splitCell",
        title: translate(TRANSLATIONS, "splitCell"),
        icon: TableSplitCell,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().splitCell().run();
        },
      },
      {
        key: "deleteTable",
        title: translate(TRANSLATIONS, "deleteTable"),
        icon: TableDeleteTable,
        command: ({ editor }: { editor: Editor }) => {
          editor.chain().focus().deleteTable().run();
        },
      },
    ]
  ],
};
