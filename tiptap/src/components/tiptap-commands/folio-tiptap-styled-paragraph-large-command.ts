import { AArrowUp } from "lucide-react";

export const FolioTiptapStyledParagraphLargeCommand: FolioEditorCommand = {
  title: { cs: "Velký text", en: "Large text" },
  icon: AArrowUp,
  key: "folioTiptapStyledParagraph-large",
  command: ({ chain }) => {
    chain.setNode("folioTiptapStyledParagraph", { variant: "large" })
  }
}

export default FolioTiptapStyledParagraphLargeCommand;
