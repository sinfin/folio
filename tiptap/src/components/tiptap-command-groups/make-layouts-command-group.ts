import { TableIcon } from "@/components/tiptap-icons";

import {
  FolioTiptapColumnsCommand,
  TableCommand,
  FolioTiptapFloatCommand,
} from "@/components/tiptap-commands"

export const makeLayoutsCommandGroup = (styledWrapCommands: FolioEditorCommand[]): FolioEditorCommandGroup => {
  return {
    title: { cs: "Rozložení", en: "Layouts" },
    key: "layouts",
    icon: TableIcon,
    commands: [
      TableCommand,
      FolioTiptapColumnsCommand,
      FolioTiptapFloatCommand,
      ...styledWrapCommands,
    ]
  }
}

export default makeLayoutsCommandGroup;
