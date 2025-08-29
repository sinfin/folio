import { HeadingTwoIcon } from "@/components/tiptap-icons/heading-two-icon"

export const HeadingTwoCommand: FolioEditorCommand = {
  title: { cs: "Nadpis H2", en: "Heading H2" },
  icon: HeadingTwoIcon,
  key: "heading-2",
  keymap: "##",
  command: ({ chain }) => {
    chain.setNode("heading", { level: 2 })
  }
}

export default HeadingTwoCommand;
