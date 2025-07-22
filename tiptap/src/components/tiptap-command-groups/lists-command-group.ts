import {
  BulletListCommand,
  OrderedListCommand,
} from "@/components/tiptap-commands"

export const ListsCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Seznamy", en: "Lists" },
  key: "lists",
  commands: [
    BulletListCommand,
    OrderedListCommand,
  ]
}

export default ListsCommandGroup;
