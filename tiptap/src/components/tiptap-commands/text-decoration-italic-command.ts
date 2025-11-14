import { ItalicIcon } from "@/components/tiptap-icons/italic-icon";

export const TextDecorationItalicCommand: FolioEditorCommand = {
  title: { cs: "Kurzíva", en: "Italic" },
  icon: ItalicIcon,
  key: "italic",
  command: ({ chain }) => {
    chain.toggleMark("italic");
  },
};

export default TextDecorationItalicCommand;
