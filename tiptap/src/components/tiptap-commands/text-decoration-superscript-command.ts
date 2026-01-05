import { SuperscriptIcon } from "@/components/tiptap-icons/superscript-icon";

export const TextDecorationSuperscriptCommand: FolioEditorCommand = {
  title: { cs: "Horní index", en: "Superscript" },
  icon: SuperscriptIcon,
  key: "superscript",
  command: ({ chain }) => {
    chain.toggleMark("superscript");
  },
};

export default TextDecorationSuperscriptCommand;
