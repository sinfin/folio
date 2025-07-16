import { Cuboid } from "lucide-react";

export const makeFolioTiptapNodeCommandGroup = (folioTiptapNodes) => {
  const items = folioTiptapNodes.map((folioTiptapNode) => ({
    title: folioTiptapNode.title,
    icon: Cuboid,
    command: ({ editor, range }: { editor: Editor; range: any }) => {
      editor.chain().focus().deleteRange(range).run();

      window.top!.postMessage(
        {
          type: "f-tiptap-slash-command:selected",
          attrs: { type: folioTiptapNode.type },
        },
        "*",
      );
    }
  }))

  return {
    title: {
      cs: "Bloky",
      en: "Blocks"
    },
    items,
  }
};

export default makeFolioTiptapNodeCommandGroup;
