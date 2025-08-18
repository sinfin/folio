import * as React from "react";
import type { Editor } from "@tiptap/react";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

export interface FolioEditorToolbarCommandButtonProps extends ButtonProps {
  editor: Editor;
  command: FolioEditorCommand;
}

export const FolioEditorToolbarCommandButton = React.forwardRef<
  HTMLButtonElement,
  FolioEditorToolbarCommandButtonProps
>(({ editor, command }, ref) => {
  if (!editor) return

  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      const chain = editor.chain()
      chain.focus()
      command.command({ chain })
      chain.run()
    },
    [command],
  );

  const label = command.title[document.documentElement.lang as keyof typeof command.title] || command.title.en;

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
      <command.icon className="tiptap-button-icon" />
    </Button>
  );
});

FolioEditorToolbarCommandButton.displayName = "FolioEditorToolbarCommandButton";

export default FolioEditorToolbarCommandButton;
