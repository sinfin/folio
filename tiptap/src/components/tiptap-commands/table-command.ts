import { Table } from "lucide-react";

export const TableCommand: FolioEditorCommand = {
  title: { cs: "Tabulka", en: "Table" },
  icon: Table,
  key: "table",
  command: ({ chain }) => {
    chain.insertTable({ rows: 2, cols: 2, withHeaderRow: true })
  }
}

export default TableCommand;
