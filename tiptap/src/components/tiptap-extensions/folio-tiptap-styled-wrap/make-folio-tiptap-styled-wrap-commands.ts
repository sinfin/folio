import { Box } from "lucide-react";

export const makeFolioTiptapStyledWrapCommands = (
  styledWrapVariants: StyledWrapVariantFromInput[],
): FolioEditorCommand[] => {
  const commands = styledWrapVariants.map((styledWrapVariant) => {
    const command: FolioEditorCommand = {
      title: styledWrapVariant.title,
      icon: Box,
      key: `styledWrapVariant-${styledWrapVariant.variant}`,
      command: ({ chain }) => {
        chain.insertContent({
          type: "folioTiptapStyledWrap",
          attrs: { variant: styledWrapVariant.variant },
          content: [
            {
              type: "paragraph",
              content: [],
            },
          ],
        });
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

export default makeFolioTiptapStyledWrapCommands;
