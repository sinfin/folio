import { AArrowDown, AArrowUp, Star, Heading } from "lucide-react";
import {
  HeadingOneIcon,
  HeadingTwoIcon,
  HeadingThreeIcon,
  HeadingFourIcon,
  HeadingFiveIcon,
  HeadingSixIcon,
} from "@/components/tiptap-icons";

export const makeFolioTiptapStyledParagraphCommands = (
  styledParagraphVariants: StyledParagraphVariantFromInput[],
): FolioEditorCommand[] => {
  const icon = (
    iconString: string | undefined,
    tagString: string | undefined,
  ) => {
    switch (iconString) {
      case "arrow-up":
        return AArrowUp;
      case "arrow-down":
        return AArrowDown;
      case "heading":
        return Heading;
    }

    switch (tagString) {
      case "h1":
        return HeadingOneIcon;
      case "h2":
        return HeadingTwoIcon;
      case "h3":
        return HeadingThreeIcon;
      case "h4":
        return HeadingFourIcon;
      case "h5":
        return HeadingFiveIcon;
      case "h6":
        return HeadingSixIcon;
      default:
        return Star;
    }

    return Star;
  };

  const commands = styledParagraphVariants.map((styledParagraphVariant) => {
    const command: FolioEditorCommand = {
      title: styledParagraphVariant.title,
      icon: icon(styledParagraphVariant.icon, styledParagraphVariant.tag),
      key: `styledParagraphVariant-${styledParagraphVariant.variant}`,
      command: ({ chain }) => {
        const attrs: Record<string, string> = {
          variant: styledParagraphVariant.variant,
        };

        chain.setNode("folioTiptapStyledParagraph", attrs);
      },
    };

    return command;
  });

  // sort commands by title
  commands.sort((a, b) => {
    const aTitle =
      a.title[document.documentElement.lang as "cs" | "en"] || a.title["en"];
    const bTitle =
      b.title[document.documentElement.lang as "cs" | "en"] || b.title["en"];

    return aTitle.localeCompare(bTitle);
  });

  return commands;
};

export default makeFolioTiptapStyledParagraphCommands;
