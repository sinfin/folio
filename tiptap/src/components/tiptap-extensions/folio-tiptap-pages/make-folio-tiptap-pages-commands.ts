import { BookOpenText } from "lucide-react";

import { TRANSLATIONS } from "./folio-tiptap-pages-node";

export const makeFolioTiptapPagesCommands = (
  enabled: boolean,
): FolioEditorCommand[] => {
  if (!enabled) return [];

  const command: FolioEditorCommand = {
    title: { cs: TRANSLATIONS.cs.label, en: TRANSLATIONS.en.label },
    icon: BookOpenText,
    key: "folioTiptapPages",
    command: ({ chain }) => {
      chain.insertFolioTiptapPages();
    },
  };

  return [command];
};

export default makeFolioTiptapPagesCommands;
