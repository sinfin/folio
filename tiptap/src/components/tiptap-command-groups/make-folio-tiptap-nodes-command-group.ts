import { Cuboid } from "lucide-react";

export const makeFolioTiptapNodesCommandGroup = (folioTiptapNodes: FolioTiptapNodeFromInput[]): FolioEditorCommandGroup => {
  const commands = folioTiptapNodes.map((folioTiptapNode) => {
    const command: FolioEditorCommand = {
      title: folioTiptapNode.title,
      icon: Cuboid,
      key: `folioTiptapNode-${folioTiptapNode.type}`,
      command: ({ chain }) => {
        window.top!.postMessage(
          {
            type: "f-tiptap-slash-command:selected",
            attrs: { type: folioTiptapNode.type },
          },
          "*",
        );
      }
    }

    return command
  })

  return {
    title: { cs: "Bloky", en: "Blocks" },
    key: "folioTiptapNodes",
    commands,
  }
}

export default makeFolioTiptapNodesCommandGroup;
