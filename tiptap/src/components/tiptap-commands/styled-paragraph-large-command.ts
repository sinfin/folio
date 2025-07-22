import { AArrowUp } from "lucide-react";

export const StyledParagraphLargeCommand: FolioEditorCommand = {
  title: { cs: "Velký text", en: "Large text" },
  icon: AArrowUp,
  key: "styledParagraph-large",
  command: ({ chain }) => {
    chain.setNode("styledParagraph", { variant: "large" })
  }
}

export default StyledParagraphLargeCommand;
