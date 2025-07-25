import { FormatImageLeft } from "@/components/tiptap-icons/format-image-left";

export const FolioTiptapFloatCommand: FolioEditorCommand = {
  title: { cs: "Obtékaný obsah", en: "Float content" },
  icon: FormatImageLeft,
  key: "folioTiptapFloatLayout",
  command: ({ chain }) => {
    chain.insertFolioTiptapFloatLayout()
  }
}

export default FolioTiptapFloatCommand;
