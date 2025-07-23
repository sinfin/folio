import { AlignLeftIcon } from "@/components/tiptap-icons/align-left-icon"

import {
  TextAlignLeftCommand,
  TextAlignCenterCommand,
  TextAlignRightCommand,
} from "@/components/tiptap-commands"

export const TextAlignCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Zarovnání", en: "Text align" },
  key: "textAlign",
  icon: AlignLeftIcon,
  commands: [
    TextAlignLeftCommand,
    TextAlignCenterCommand,
    TextAlignRightCommand,
  ]
}

export default TextAlignCommandGroup;
