import { StrikeIcon } from "@/components/tiptap-icons/strike-icon";

export const TextDecorationStrikeCommand: FolioEditorCommand = {
  title: { cs: "Přeškrtnuté", en: "Strikethrough" },
  icon: StrikeIcon,
  key: "strike",
  command: ({ chain }) => {
    chain.toggleMark("strike");
  },
};

export default TextDecorationStrikeCommand;
