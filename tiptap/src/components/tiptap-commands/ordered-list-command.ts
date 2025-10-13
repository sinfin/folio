import { ListOrderedIcon } from "@/components/tiptap-icons/list-ordered-icon";

export const OrderedListCommand: FolioEditorCommand = {
  title: { cs: "Číslovaný seznam", en: "Ordered List" },
  icon: ListOrderedIcon,
  key: "orderedList",
  command: ({ chain }) => {
    chain.toggleOrderedList();
  },
};

export default OrderedListCommand;
