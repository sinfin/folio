import { Columns2 } from "lucide-react";

export const FolioTiptapColumnsCommand: FolioEditorCommand = {
  title: { cs: "Sloupce", en: "Columns" },
  icon: Columns2,
  key: "folioTiptapColumns",
  command: ({ chain }) => {
    chain.insertColumns({ count: 2 })
  }
}

export default FolioTiptapColumnsCommand;
