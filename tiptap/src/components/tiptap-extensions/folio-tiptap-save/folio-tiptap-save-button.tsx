import * as React from "react";
import type { Editor } from "@tiptap/react";
import { Save, SaveOff } from "lucide-react";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    saveAt: "Uloženo v",
    saveOn: "Uloženo",
  },
  en: {
    saveAt: "Saved at",
    saveOn: "Saved on",
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
  const [newRecord, setNewRecord] = React.useState<boolean>(true);

  React.useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data?.type === 'f-input-tiptap:save-button-info') {
        setNewRecord(event.data.newRecord || false);

        if (event.data.latestRevisionCreatedAt) {
          setLastSavedAt(new Date(event.data.latestRevisionCreatedAt));
        }
      } else if (event.data?.type === 'f-input-tiptap:auto-saved') {
        setLastSavedAt(new Date(event.data.createdAt));
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const label = lastSavedAt
    ? formatSaveLabel(lastSavedAt)
    : translate(TRANSLATIONS, "saveAt");

  function formatSaveLabel(date: Date): string {
    const now = new Date();
    const isToday = date.toDateString() === now.toDateString();

    if (isToday) {
      // Time only for today: "Uloženo v 14:23" / "Saved at 14:23"
      const timeStr = date.toLocaleTimeString("cs-CZ", {
        hour: '2-digit',
        minute: '2-digit'
      });
      return `${translate(TRANSLATIONS, "saveAt")} ${timeStr}`;
    } else {
      // Date + time for older saves: "Uloženo 31.8. 14:23" / "Saved on 31.8. 14:23"
      const dateTimeStr = date.toLocaleDateString("cs-CZ", {
        day: 'numeric',
        month: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
      return `${translate(TRANSLATIONS, "saveOn")} ${dateTimeStr}`;
    }
  }

  if (newRecord) {
    return (
      <Button
        ref={ref}
        type="button"
        data-style="ghost"
        role="button"
        tabIndex={-1}
        style={{ pointerEvents: 'none' }}
      >
        <SaveOff className="tiptap-button-icon" color="#FF9A52" />
      </Button>
    );
  }

  return (
    <Button
      ref={ref}
      type="button"
      data-style="ghost"
      role="button"
      tabIndex={-1}
      aria-label={label}
      tooltip={label}
      style={{ cursor: 'default' }}
    >
      <Save className="tiptap-button-icon" />
    </Button>
  );
});

FolioTiptapSaveButton.displayName = "FolioTiptapSaveButton";

export default FolioTiptapSaveButton;
