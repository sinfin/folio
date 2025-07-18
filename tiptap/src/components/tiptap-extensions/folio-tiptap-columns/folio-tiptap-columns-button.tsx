import * as React from "react";
import type { Range } from "@tiptap/core";
import type { Editor, Content } from "@tiptap/react";
import { Columns2 } from "lucide-react";

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import { type UntranslatedCommandItem } from "@/components/tiptap-ui/commands/commands-list";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    addColumns: "Přidat sloupce",
  },
  en: {
    addColumns: "Add columns",
  }
}

export const FolioTiptapColumnsCommandItem: UntranslatedCommandItem = {
  title: { cs: "Sloupce", en: "Columns" },
  icon: Columns2,
  command: ({ editor, range }: { editor: Editor, range: Range }) => {
    editor
      .chain()
      .focus()
      .deleteRange(range)
      .insertColumns({ count: 2 })
      .run();
  },
}

export interface FolioTiptapColumnsButtonProps extends ButtonProps {
  editor: Editor | null;
}

export const FolioTiptapColumnsButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapColumnsButtonProps
>(({ editor: providedEditor, disabled }, ref) => {
  const editor = useTiptapEditor(providedEditor);

  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented && !disabled && editor) {
        editor.chain().focus().insertColumns({ count: 2 }).run();
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
      <Columns2 className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapColumnsButton.displayName = "FolioTiptapColumnsButton";

export default FolioTiptapColumnsButton;
