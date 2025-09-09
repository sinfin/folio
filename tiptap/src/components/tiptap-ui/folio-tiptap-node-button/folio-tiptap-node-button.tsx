"use client";

import * as React from "react";
import type { Editor, Content } from "@tiptap/react";
import { Plus } from "lucide-react";

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    insert: "Vložit obsah",
  },
  en: {
    insert: "Insert content",
  },
};

export interface FolioTiptapNodeButtonProps extends ButtonProps {
  editor: Editor | null;
  disabled?: boolean;
}

export function insertFolioTiptapNode(
  editor: Editor | null,
  node: any,
): boolean {
  if (!editor) {
    console.log("No editor available for insertFolioTiptapNode");
    return false;
  }

  try {
    return editor.commands.insertFolioTiptapNode(node);
  } catch (error) {
    console.error("insertFolioTiptapNode error", error);
    return false;
  }
}

export const FolioTiptapNodeButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapNodeButtonProps
>(({ editor, disabled }, ref) => {
  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented && !disabled && editor) {
        editor
          .chain()
          .focus()
          .triggerFolioTiptapCommand(null)
          .run();
      }
    },
    [disabled],
  );

  React.useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (
        process.env.NODE_ENV === "production" &&
        event.origin !== window.origin
      )
        return;
      if (!event.data || event.data.type !== "f-c-tiptap-overlay:saved") return;

      if (event.data.uniqueId) {
        // handle these in folio-tiptap-node.tsx
        return;
      }

      // Handle window message events here
      insertFolioTiptapNode(editor, event.data.node);
    };

    window.addEventListener("message", handleMessage);

    return () => {
      window.removeEventListener("message", handleMessage);
    };
  }, [editor]);

  if (!editor || !editor.isEditable) {
    return null;
  }

  const label = translate(TRANSLATIONS, "insert");

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
      <Plus className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapNodeButton.displayName = "FolioTiptapNodeButton";

export default FolioTiptapNodeButton;
