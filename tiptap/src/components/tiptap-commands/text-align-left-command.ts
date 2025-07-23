import { AlignLeftIcon } from "@/components/tiptap-icons/align-left-icon"

export const TextAlignLeftCommand: FolioEditorCommand = {
  title: { cs: "Zarovnat doleva", en: "Align left" },
  icon: AlignLeftIcon,
  key: "align-left",
  command: ({ chain }) => {
    chain.setTextAlign("left")
  }
}

export default TextAlignLeftCommand;
