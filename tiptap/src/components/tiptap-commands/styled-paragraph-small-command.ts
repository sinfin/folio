import { AArrowDown } from "lucide-react";

export const StyledParagraphSmallCommand: FolioEditorCommand = {
  title: { cs: "Malý text", en: "Small text" },
  icon: AArrowDown,
  key: "styledParagraph-small",
  command: ({ chain }) => {
    chain.setNode("styledParagraph", { variant: "small" })
  }
}

export default StyledParagraphSmallCommand;
