import { Pilcrow } from "lucide-react";

export const ParagraphCommand: FolioEditorCommand = {
  title: { cs: "Odstavec", en: "Paragraph" },
  icon: Pilcrow,
  key: "paragraph",
  dontShowAsActiveInCollapsedToolbar: true,
  command: ({ chain }) => {
    chain.setNode("paragraph");
  },
};

export default ParagraphCommand;
