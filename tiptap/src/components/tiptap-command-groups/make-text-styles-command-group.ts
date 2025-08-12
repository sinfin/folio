import { HeadingIcon } from '@/components/tiptap-icons/heading-icon';

import {
  HeadingFourCommand,
  HeadingThreeCommand,
  HeadingTwoCommand,
  ParagraphCommand,
} from "@/components/tiptap-commands"

export const makeTextStylesCommandGroup = (styledParagraphCommands: FolioEditorCommand[]): FolioEditorCommandGroup => {
  return {
    title: { cs: "Formát textu", en: "Text format" },
    key: "textStyles",
    icon: HeadingIcon,
    commands: [
      ParagraphCommand,
      HeadingTwoCommand,
      HeadingThreeCommand,
      HeadingFourCommand,
      ...styledParagraphCommands,
    ]
  }
}

export default makeTextStylesCommandGroup;
