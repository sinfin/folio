import * as React from "react";
import { type Editor } from "@tiptap/react";

import { Button } from "@/components/tiptap-ui-primitive/button";
import { ImageIcon } from '@/components/tiptap-icons';
import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    insert: "Vložit obrázek",
  },
  en: {
    insert: "Insert image",
  },
};

export interface FolioTiptapNodeButtonForSingleImageProps {
  editor: Editor;
  singleImageNodeForToolbar: FolioTiptapNodeFromInput | null;
}

export const FolioTiptapNodeButtonForSingleImage = ({ editor, singleImageNodeForToolbar }: FolioTiptapNodeButtonForSingleImageProps) => {
  if (!singleImageNodeForToolbar) return
  if (!editor || !editor.isEditable) return null;

  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      window.top!.postMessage(
        {
          type: "f-tiptap-slash-command:selected",
          attrs: { type: singleImageNodeForToolbar.type },
        },
        "*",
      );
    },
    [singleImageNodeForToolbar],
  );

  const label = translate(TRANSLATIONS, "insert");

  return (
    <Button
      type="button"
      data-style="ghost"
      role="button"
      tabIndex={-1}
      aria-label={label}
      tooltip={label}
      onClick={handleClick}
    >
      <ImageIcon className="tiptap-button-icon" />
    </Button>
  );
}

FolioTiptapNodeButtonForSingleImage.displayName = "FolioTiptapNodeButtonForSingleImage";

export default FolioTiptapNodeButtonForSingleImage;
