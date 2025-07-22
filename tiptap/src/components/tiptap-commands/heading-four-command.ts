import { HeadingFourIcon } from "@/components/tiptap-icons/heading-four-icon"

export const HeadingFourCommand: FolioEditorCommand = {
  title: { cs: "Nadpis H4", en: "Heading H4" },
  icon: HeadingFourIcon,
  key: "heading-4",
  command: ({ chain }) => {
    chain.setNode("heading", { level: 4 })
  }
}

export default HeadingFourCommand;
