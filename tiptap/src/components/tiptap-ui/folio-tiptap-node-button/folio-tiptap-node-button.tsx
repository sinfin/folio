"use client";

import * as React from "react";
import type { Editor, Content } from "@tiptap/react";
import { Plus } from "lucide-react";

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

export interface FolioTiptapNodeButtonProps extends ButtonProps {
  editor: Editor | null;
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
>(({ editor: providedEditor, disabled }, ref) => {
  const editor = useTiptapEditor(providedEditor);

  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented && !disabled && editor) {
        let currentPos = editor.state.selection.$from.pos;
        let currentNode = editor.state.doc.nodeAt(currentPos);

        let targetPos

        if (currentNode) {
          // If we're inside a node, insert the new one after
          const $pos = editor.state.doc.resolve(currentPos);
          targetPos = $pos.start($pos.depth) + currentNode.nodeSize + 1;
        } else {
          // if we're outside a node, insert the new one at the current position
          targetPos = currentPos + 1;
        }

        editor
          .chain()
          .focus()
          .insertContentAt(targetPos - 1, {
            type: "paragraph",
            content: [{ type: "text", text: "/" }],
          })
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
      <Plus className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapNodeButton.displayName = "FolioTiptapNodeButton";

export default FolioTiptapNodeButton;
