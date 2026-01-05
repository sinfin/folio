import { SubscriptIcon } from "@/components/tiptap-icons/subscript-icon";

export const TextDecorationSubscriptCommand: FolioEditorCommand = {
  title: { cs: "Dolní index", en: "Subscript" },
  icon: SubscriptIcon,
  key: "subscript",
  command: ({ chain }) => {
    chain.toggleMark("subscript");
  },
};

export default TextDecorationSubscriptCommand;
