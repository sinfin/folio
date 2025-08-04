import { TableIcon } from "@/components/tiptap-icons";

import {
  FolioTiptapColumnsCommand,
  TableCommand,
  FolioTiptapFloatCommand,
} from "@/components/tiptap-commands"

export const LayoutsCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Rozložení", en: "Layouts" },
  key: "layouts",
  icon: TableIcon,
  commands: [
    TableCommand,
    FolioTiptapColumnsCommand,
    FolioTiptapFloatCommand,
  ]
}

export default LayoutsCommandGroup;
