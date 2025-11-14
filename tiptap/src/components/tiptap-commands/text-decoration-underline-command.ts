import { UnderlineIcon } from "@/components/tiptap-icons/underline-icon";

export const TextDecorationUnderlineCommand: FolioEditorCommand = {
  title: { cs: "Podtržené", en: "Underline" },
  icon: UnderlineIcon,
  key: "underline",
  command: ({ chain }) => {
    chain.toggleMark("underline");
  },
};

export default TextDecorationUnderlineCommand;
