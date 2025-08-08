import { AArrowDown } from "lucide-react";

export const FolioTiptapStyledParagraphSmallCommand: FolioEditorCommand = {
  title: { cs: "Malý text", en: "Small text" },
  icon: AArrowDown,
  key: "folioTiptapStyledParagraph-small",
  command: ({ chain }) => {
    chain.setNode("folioTiptapStyledParagraph", { variant: "small" })
  }
}

export default FolioTiptapStyledParagraphSmallCommand;
