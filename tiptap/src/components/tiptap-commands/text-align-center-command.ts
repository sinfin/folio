import { AlignCenterIcon } from "@/components/tiptap-icons/align-center-icon";

export const TextAlignCenterCommand: FolioEditorCommand = {
  title: { cs: "Zarovnat doprostřed", en: "Align center" },
  icon: AlignCenterIcon,
  key: "align-center",
  command: ({ chain }) => {
    chain.setTextAlign("center");
  },
};

export default TextAlignCenterCommand;
