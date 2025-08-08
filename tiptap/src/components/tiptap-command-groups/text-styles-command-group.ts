import { HeadingIcon } from '@/components/tiptap-icons/heading-icon';

import {
  HeadingFourCommand,
  HeadingThreeCommand,
  HeadingTwoCommand,
  ParagraphCommand,
  FolioTiptapStyledParagraphLargeCommand,
  FolioTiptapStyledParagraphSmallCommand,
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
    FolioTiptapStyledParagraphLargeCommand,
    FolioTiptapStyledParagraphSmallCommand,
  ]
}

export default TextStylesCommandGroup;
