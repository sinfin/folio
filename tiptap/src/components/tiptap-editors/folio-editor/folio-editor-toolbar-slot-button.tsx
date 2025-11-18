import * as React from "react";
import { type Editor } from "@tiptap/react";

import { Button } from "@/components/tiptap-ui-primitive/button";
import translate from "@/lib/i18n";

import {
  Video,
  Image,
  Newspaper,
  Plus
} from "lucide-react";

export interface FolioEditorToolbarSlotButton {
  editor: Editor;
  node: FolioTiptapNodeFromInput;
}

const TRANSLATIONS = {
  cs: "Vložit",
  en: "Insert",
}

export const FolioEditorToolbarSlotButton = ({
  editor,
  node,
}: FolioEditorToolbarSlotButton) => {
  const handleClick = React.useCallback(() => {
    window.parent!.postMessage(
      {
        type: "f-tiptap-slash-command:selected",
        attrs: { type: node?.type },
      },
      "*",
    );
  }, [node]);

  const icon = (iconString: string | undefined) => {
    switch (iconString) {
      case "image":
        return Image;
      case "video":
        return Video;
      case "newspaper":
        return Newspaper;
      default:
        console.warn(`Unknown icon string: ${iconString}`);
        return Plus;
    }
  }

  if (!node) return;
  if (!editor || !editor.isEditable) return null;

  const translations = {
    cs: {
      insert: node.title.cs || TRANSLATIONS.cs
    },
    en: {
      insert: node.title.en || TRANSLATIONS.en
    }
  }

  const label = translate(translations, "insert");
  const IconComponent = icon(node.config.toolbar?.icon);

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
      <IconComponent />
    </Button>
  );
};

FolioEditorToolbarSlotButton.displayName =
  "FolioEditorToolbarSlotButton";

export default FolioEditorToolbarSlotButton;
