import { ItalicIcon } from "@/components/tiptap-icons/italic-icon";

import {
  TextDecorationItalicCommand,
  TextDecorationUnderlineCommand,
  TextDecorationStrikeCommand,
  TextDecorationSuperscriptCommand,
  TextDecorationSubscriptCommand,
} from "@/components/tiptap-commands";

export const TextDecorationCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Dekorace textu", en: "Text Decorations" },
  key: "textDecorations",
  icon: ItalicIcon,
  commands: [
    TextDecorationItalicCommand,
    TextDecorationUnderlineCommand,
    TextDecorationStrikeCommand,
    TextDecorationSuperscriptCommand,
    TextDecorationSubscriptCommand,
  ],
};

export default TextDecorationCommandGroup;
