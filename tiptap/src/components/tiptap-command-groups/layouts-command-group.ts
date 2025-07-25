import { Columns2 } from "lucide-react";

import {
  FolioTiptapColumnsCommand,
  TableCommand,
  FolioTiptapFloatCommand,
} from "@/components/tiptap-commands"

export const LayoutsCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Rozložení", en: "Layouts" },
  key: "layouts",
  icon: Columns2,
  commands: [
    TableCommand,
    FolioTiptapColumnsCommand,
    FolioTiptapFloatCommand,
  ]
}

export default LayoutsCommandGroup;
