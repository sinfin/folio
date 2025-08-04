import { TableIcon } from "@/components/tiptap-icons";

export const TableCommand: FolioEditorCommand = {
  title: { cs: "Tabulka", en: "Table" },
  icon: TableIcon,
  key: "table",
  command: ({ chain }) => {
    chain.insertTable({ rows: 2, cols: 2, withHeaderRow: true })
  }
}

export default TableCommand;
