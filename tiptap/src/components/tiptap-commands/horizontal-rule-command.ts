import { Minus } from "lucide-react";

export const HorizontalRuleCommand: FolioEditorCommand = {
  title: { cs: "Oddělovač", en: "Delimiter" },
  icon: Minus,
  key: "horizontalRule",
  hideInToolbarDropdown: true,
  command: ({ chain }) => {
    chain.insertContent({ type: "horizontalRule" })
  }
}

export default HorizontalRuleCommand;
