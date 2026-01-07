import * as React from "react";
import { type Editor } from "@tiptap/react";

import { Button } from "@/components/tiptap-ui-primitive/button";
import translate from "@/lib/i18n";
import { getNodeIcon } from "@/lib/node-icons";

export interface FolioEditorToolbarSlotButton {
  editor: Editor;
  node: FolioTiptapNodeFromInput;
}

const TRANSLATIONS = {
  cs: "Vložit",
  en: "Insert",
};

export const FolioEditorToolbarSlotButton = ({
  editor,
  node,
}: FolioEditorToolbarSlotButton) => {
  // Intentional use of "*" origin for parent iframe communication
  const handleClick = React.useCallback(() => {
    window.parent!.postMessage(
      {
        type: "f-tiptap-slash-command:selected",
        attrs: { type: node?.type },
      },
      "*",
    );
  }, [node]);

  if (!node) return;
  if (!editor || !editor.isEditable) return null;

  const translations = {
    cs: {
      insert: node.title.cs || TRANSLATIONS.cs,
    },
    en: {
      insert: node.title.en || TRANSLATIONS.en,
    },
  };

  const label = translate(translations, "insert");
  const IconComponent = getNodeIcon(node.config?.icon);

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
      <IconComponent size={16} />
    </Button>
  );
};

FolioEditorToolbarSlotButton.displayName = "FolioEditorToolbarSlotButton";

export default FolioEditorToolbarSlotButton;
