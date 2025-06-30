"use client";

import * as React from "react";
import type { Editor, Content } from "@tiptap/react";

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor";

// --- Icons ---
import { BlocksIcon } from "@/components/tiptap-icons/blocks-icon";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

export interface FolioTiptapNodeButtonProps extends ButtonProps {
  editor: Editor | null;
  folioTiptapNodes?: string[];
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
    const result = editor.commands.insertContent(node);
    return result;
  } catch (error) {
    console.error("insertFolioTiptapNode error", error);
    return false;
  }
}

export const FolioTiptapNodeButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapNodeButtonProps
>(({ editor: providedEditor, disabled, folioTiptapNodes }, ref) => {
  const editor = useTiptapEditor(providedEditor);

  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (
        !e.defaultPrevented &&
        !disabled &&
        folioTiptapNodes &&
        folioTiptapNodes[0]
      ) {
        window.top!.postMessage(
          {
            type: "f-tiptap-node-button:click",
            attrs: { type: folioTiptapNodes[0] },
          },
          "*",
        );
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

  return (
    <Button
      ref={ref}
      type="button"
      data-style="ghost"
      role="button"
      tabIndex={-1}
      aria-label="Add Folio Tiptap Node"
      tooltip="Add Folio Tiptap Node"
      onClick={handleClick}
    >
      <BlocksIcon className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapNodeButton.displayName = "FolioTiptapNodeButton";

export default FolioTiptapNodeButton;
