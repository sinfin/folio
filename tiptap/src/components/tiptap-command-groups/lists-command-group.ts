import { ListIcon } from "@/components/tiptap-icons/list-icon";

import {
  BulletListCommand,
  OrderedListCommand,
} from "@/components/tiptap-commands";

export const ListsCommandGroup: FolioEditorCommandGroup = {
  title: { cs: "Seznamy", en: "Lists" },
  key: "lists",
  icon: ListIcon,
  commands: [BulletListCommand, OrderedListCommand],
};

export default ListsCommandGroup;
