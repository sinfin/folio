import { HeadingIcon } from '@/components/tiptap-icons/heading-icon';

import {
  HeadingFourCommand,
  HeadingThreeCommand,
  HeadingTwoCommand,
  ParagraphCommand,
} from "@/components/tiptap-commands"

interface MakeTextStylesCommandGroupProps {
  folioTiptapStyledParagraphCommands: FolioEditorCommand[];
  folioTiptapHeadingLevels: number[];
}

export const makeTextStylesCommandGroup = ({ folioTiptapStyledParagraphCommands, folioTiptapHeadingLevels }: MakeTextStylesCommandGroupProps): FolioEditorCommandGroup => {
  const headingCommands = []

  if (folioTiptapHeadingLevels) {
    if (folioTiptapHeadingLevels.includes(2)) {
      headingCommands.push(HeadingTwoCommand);
    }
    if (folioTiptapHeadingLevels.includes(3)) {
      headingCommands.push(HeadingThreeCommand);
    }
    if (folioTiptapHeadingLevels.includes(4)) {
      headingCommands.push(HeadingFourCommand);
    }
  }

  if (folioTiptapHeadingLevels.length === 1) {
    headingCommands[0].title = { cs: "Mezititulek", en: "Title" }
  }

  return {
    title: { cs: "Formát textu", en: "Text format" },
    key: "textStyles",
    icon: HeadingIcon,
    commands: [
      ParagraphCommand,
      ...headingCommands,
      ...folioTiptapStyledParagraphCommands,
    ]
  }
}

export default makeTextStylesCommandGroup;
