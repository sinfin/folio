import { ListIcon } from "@/components/tiptap-icons/list-icon";

export const BulletListCommand: FolioEditorCommand = {
  title: { cs: "Bodový seznam", en: "Bullet List" },
  icon: ListIcon,
  key: "bulletList",
  command: ({ chain }) => {
    chain.toggleBulletList();
  },
};

export default BulletListCommand;
