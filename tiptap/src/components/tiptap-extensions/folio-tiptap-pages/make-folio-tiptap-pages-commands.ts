import { BookOpenText } from "lucide-react";

import { TRANSLATIONS } from './folio-tiptap-page-node';

export const makeFolioTiptapPagesCommands = (styledWrapVariants: StyledWrapVariantFromInput[]): FolioEditorCommand[] => {
  const command: FolioEditorCommand = {
    title: { cs: TRANSLATIONS.cs.label, en: TRANSLATIONS.en.label },
    icon: BookOpenText,
    key: "folioTiptapPages",
    command: ({ chain }) => {
      chain.insertFolioTiptapPages()
    }
  }

  return [command]
}

export default makeFolioTiptapPagesCommands;
