import { HeadingThreeIcon } from "@/components/tiptap-icons/heading-three-icon"

export const HeadingThreeCommand: FolioEditorCommand = {
  title: { cs: "Nadpis H3", en: "Heading H3" },
  icon: HeadingThreeIcon,
  key: "heading-3",
  keymap: "###",
  command: ({ chain }) => {
    chain.setNode("heading", { level: 3 })
  }
}

export default HeadingThreeCommand;
