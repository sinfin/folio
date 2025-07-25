import * as React from "react";
import type { Range } from "@tiptap/core";
import type { Editor, Content } from "@tiptap/react";
import { FormatImageLeft } from "@/components/tiptap-icons/format-image-left";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addColumns: "Přidat obtékaný obsah",
  },
  en: {
    addColumns: "Add float layout",
  }
}

export interface FolioTiptapFloatButtonProps extends ButtonProps {
  editor: Editor;
}

export const FolioTiptapFloatButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapFloatButtonProps
>(({ editor, disabled }, ref) => {
  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented && !disabled && editor) {
        editor.chain().focus().insertFolioTiptapFloat().run();
      }
    },
    [disabled],
  );

  if (!editor || !editor.isEditable) {
    return null;
  }

  const label = translate(TRANSLATIONS, "addColumns");

  return (
    <Button
      ref={ref}
      type="button"
      data-style="ghost"
      role="button"
      tabIndex={-1}
      aria-label={label}
      tooltip={label}
      onClick={handleClick}
    >
      <FormatImageLeft className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapFloatButton.displayName = "FolioTiptapFloatButton";

export default FolioTiptapFloatButton;
