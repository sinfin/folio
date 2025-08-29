import { TableIcon } from "@/components/tiptap-icons";

import {
  FolioTiptapColumnsCommand,
  TableCommand,
  FolioTiptapFloatCommand,
  HorizontalRuleCommand,
} from "@/components/tiptap-commands"

interface MakeLayoutsCommandGroupProps {
  folioTiptapStyledWrapCommands: FolioEditorCommand[];
  folioTiptapPagesCommands: FolioEditorCommand[];
}

export const makeLayoutsCommandGroup = ({ folioTiptapStyledWrapCommands, folioTiptapPagesCommands }: MakeLayoutsCommandGroupProps): FolioEditorCommandGroup => {
  return {
    title: { cs: "Rozložení", en: "Layouts" },
    key: "layouts",
    icon: TableIcon,
    commands: [
      TableCommand,
      FolioTiptapColumnsCommand,
      FolioTiptapFloatCommand,
      ...folioTiptapStyledWrapCommands,
      ...folioTiptapPagesCommands,
      HorizontalRuleCommand,
    ]
  }
}

export default makeLayoutsCommandGroup;
