import { Columns2 } from "lucide-react";

import {
  FolioTiptapColumnsCommand,
} from "@/components/tiptap-commands"

export const LayoutsCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Rozložení", en: "Layouts" },
  key: "layouts",
  icon: Columns2,
  commands: [
    FolioTiptapColumnsCommand,
  ]
}

export default LayoutsCommandGroup;
