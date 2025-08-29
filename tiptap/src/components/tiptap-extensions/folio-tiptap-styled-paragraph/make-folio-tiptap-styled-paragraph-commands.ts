import {
  AArrowDown,
  AArrowUp,
  Star,
} from "lucide-react";

export const makeFolioTiptapStyledParagraphCommands = (styledParagraphVariants: StyledParagraphVariantFromInput[]): FolioEditorCommand[] => {
  const icon = (any: string | undefined) => {
    if (any === "arrow-up") {
      return AArrowUp
    } else if (any === "arrow-down") {
      return AArrowDown
    }

    return Star
  }

  const commands = styledParagraphVariants.map((styledParagraphVariant) => {
    const command: FolioEditorCommand = {
      title: styledParagraphVariant.title,
      icon: icon(styledParagraphVariant.icon),
      key: `styledParagraphVariant-${styledParagraphVariant.variant}`,
      command: ({ chain }) => {
        chain.setNode("folioTiptapStyledParagraph", { variant: styledParagraphVariant.variant })
      }
    }

    return command
  })

  // sort commands by title
  commands.sort((a, b) => {
    const aTitle = a.title[document.documentElement.lang as "cs" | "en"] || a.title["en"];
    const bTitle = b.title[document.documentElement.lang as "cs" | "en"] || b.title["en"];

    return aTitle.localeCompare(bTitle);
  });

  return commands
}

export default makeFolioTiptapStyledParagraphCommands;
