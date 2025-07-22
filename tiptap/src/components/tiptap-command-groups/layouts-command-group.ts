import { Columns2 } from "lucide-react";

import {
  FolioTiptapColumnsCommand,
  TableCommand,
} from "@/components/tiptap-commands"

export const LayoutsCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Rozložení", en: "Layouts" },
  key: "layouts",
  icon: Columns2,
  commands: [
    TableCommand,
    FolioTiptapColumnsCommand,
  ]
}

export default LayoutsCommandGroup;
