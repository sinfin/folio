import { HeadingIcon } from '@/components/tiptap-icons/heading-icon';

import {
  HeadingFourCommand,
  HeadingThreeCommand,
  HeadingTwoCommand,
  ParagraphCommand,
  StyledParagraphLargeCommand,
  StyledParagraphSmallCommand,
} from "@/components/tiptap-commands"

export const TextStylesCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Formát textu", en: "Text format" },
  key: "textStyles",
  icon: HeadingIcon,
  commands: [
    ParagraphCommand,
    HeadingTwoCommand,
    HeadingThreeCommand,
    HeadingFourCommand,
    StyledParagraphLargeCommand,
    StyledParagraphSmallCommand,
  ]
}

export default TextStylesCommandGroup;
