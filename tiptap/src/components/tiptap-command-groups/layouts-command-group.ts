import {
  FolioTiptapColumnsCommand,
} from "@/components/tiptap-commands"

export const LayoutsCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Rozložení", en: "Layouts" },
  key: "layouts",
  commands: [
    FolioTiptapColumnsCommand,
  ]
}

export default LayoutsCommandGroup;
