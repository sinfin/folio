import { Cuboid } from "lucide-react";

export const makeFolioTiptapNodesCommandGroup = (
  folioTiptapNodes: FolioTiptapNodeFromInput[],
): FolioEditorCommandGroup => {
  const commands = folioTiptapNodes.map((folioTiptapNode) => {
    const command: FolioEditorCommand = {
      title: folioTiptapNode.title,
      icon: Cuboid,
      key: `folioTiptapNode-${folioTiptapNode.type}`,
      command: () => {
        // blur editor to prevent input
        if (document.activeElement instanceof HTMLElement) {
          document.activeElement.blur();
        }

        window.parent!.postMessage(
          {
            type: "f-tiptap-slash-command:selected",
            attrs: { type: folioTiptapNode.type },
          },
          "*",
        );
      },
    };

    return command;
  });

  // sort commands by title
  commands.sort((a, b) => {
    const aTitle =
      a.title[document.documentElement.lang as "cs" | "en"] || a.title["en"];
    const bTitle =
      b.title[document.documentElement.lang as "cs" | "en"] || b.title["en"];

    return aTitle.localeCompare(bTitle);
  });

  return {
    title: { cs: "Bloky", en: "Blocks" },
    key: "folioTiptapNodes",
    icon: Cuboid,
    commands,
  };
};

export default makeFolioTiptapNodesCommandGroup;
