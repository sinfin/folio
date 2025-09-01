import * as React from "react";
import type { Editor } from "@tiptap/react";
import { Save } from "lucide-react";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    save: "Uloženo v",
  },
  en: {
    save: "Saved at",
  },
};

export interface FolioTiptapSaveButtonProps extends ButtonProps {
  editor: Editor;
}

export const FolioTiptapSaveButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapSaveButtonProps
>(({ editor }, ref) => {
  const [lastSavedAt, setLastSavedAt] = React.useState<Date | null>(null);

  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented) {
        const html = editor.getHTML();

        window.parent!.postMessage(
          {
            type: "f-tiptap-editor:save",
            html,
          },
          "*",
        );

        setLastSavedAt(new Date());
      }
    },
    [],
  );

  React.useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data?.type === 'f-input-tiptap:auto-saved') {
        setLastSavedAt(new Date(event.data.createdAt));
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const baseLabel = translate(TRANSLATIONS, "save");
  const label = lastSavedAt
    ? `${baseLabel} ${lastSavedAt.toLocaleTimeString("cs-CZ", {
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
      })}`
    : baseLabel;

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
      <Save className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapSaveButton.displayName = "FolioTiptapSaveButton";

export default FolioTiptapSaveButton;
