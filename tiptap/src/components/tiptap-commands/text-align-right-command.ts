import { AlignRightIcon } from "@/components/tiptap-icons/align-right-icon"

export const TextAlignRightCommand: FolioEditorCommand = {
  title: { cs: "Zarovnat doprava", en: "Align right" },
  icon: AlignRightIcon,
  key: "align-right",
  command: ({ chain }) => {
    chain.setTextAlign("right")
  }
}

export default TextAlignRightCommand;
