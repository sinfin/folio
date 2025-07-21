import * as React from "react";
import type { Range } from "@tiptap/core";
import type { Editor, Content } from "@tiptap/react";
import { Eraser } from "lucide-react";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    erase: "Smazat formátování",
  },
  en: {
    erase: "Erase formatting",
  },
};

export interface FolioTiptapEraseMarksButtonProps extends ButtonProps {
  editor: Editor;
  enabled: boolean;
}

export const FolioTiptapEraseMarksButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapEraseMarksButtonProps
>(({ editor, enabled }, ref) => {
  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented) {
        const selection = editor.view.state.selection;

        if (selection.empty) {
          // expand selection to current node
          const textNode = editor.view.state.doc.nodeAt(selection.from);
          if (textNode && textNode.marks && textNode.marks.length > 0) {
            const resolvedPos = editor.view.state.doc.resolve(selection.from);
            let nodeStart = resolvedPos.start(resolvedPos.depth + 1);

            if (isNaN(nodeStart)) {
              nodeStart = selection.from;
            }

            const range: Range = {
              from: nodeStart - 1,
              to: nodeStart + textNode.nodeSize + 1,
            };

            // remove node marks
            editor.chain().focus().setTextSelection(range).unsetAllMarks().run();
          }
        } else {
          editor.chain().focus().unsetAllMarks().run();
        }
      }
    },
    [],
  );

  const label = translate(TRANSLATIONS, "erase");

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
      disabled={!enabled}
      data-disabled={!enabled}
    >
      <Eraser className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapEraseMarksButton.displayName = "FolioTiptapEraseMarksButton";

export default FolioTiptapEraseMarksButton;
