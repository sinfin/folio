import * as React from "react";
import type { Editor } from "@tiptap/react";
import { Code } from "lucide-react";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    showHtml: "Zobrazit HTML kód",
  },
  en: {
    showHtml: "Show HTML code",
  },
};

export interface FolioTiptapShowHtmlButtonProps extends ButtonProps {
  editor: Editor;
}

export const FolioTiptapShowHtmlButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapShowHtmlButtonProps
>(({ editor }, ref) => {
  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented) {
        const html = editor.getHTML();

        window.parent!.postMessage(
          {
            type: "f-tiptap-editor:show-html",
            html,
          },
          "*",
        );
      }
    },
    [],
  );

  const label = translate(TRANSLATIONS, "showHtml");

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
      <Code className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapShowHtmlButton.displayName = "FolioTiptapShowHtmlButton";

export default FolioTiptapShowHtmlButton;
