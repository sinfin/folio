import { Cuboid } from "lucide-react";
import { type Range, type Editor } from "@tiptap/core";

import { type CommandItem } from "@/components/tiptap-ui/commands/commands-list";
import { normalizeString } from "@/components/tiptap-ui/commands/suggestion"

export const makeFolioTiptapNodeCommandGroup = (
  folioTiptapNodes: FolioTiptapNodeFromInput[],
) => {
  const items = folioTiptapNodes.map(
    (folioTiptapNode: FolioTiptapNodeFromInput): CommandItem => ({
      title: folioTiptapNode.title,
      normalizedTitle: normalizeString(folioTiptapNode.title),
      icon: Cuboid,
      command: ({ editor, range }: { editor: Editor; range: Range }) => {
        editor.chain().focus().deleteRange(range).run();

        window.top!.postMessage(
          {
            type: "f-tiptap-slash-command:selected",
            attrs: { type: folioTiptapNode.type },
          },
          "*",
        );
      },
    }),
  );

  return {
    title: {
      cs: "Bloky",
      en: "Blocks",
    },
    items,
  };
};

export default makeFolioTiptapNodeCommandGroup;
