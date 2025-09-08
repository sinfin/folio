import * as React from "react";
import type { Editor } from "@tiptap/react";
import { AlertTriangle, Save, SaveOff } from "lucide-react";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    saveAt: "Uloženo v",
    saveOn: "Uloženo",
    failedToAutosave: "Chyba ukládání rozpracovaného textu."
  },
  en: {
    saveAt: "Saved at",
    saveOn: "Saved on",
    failedToAutosave: "Failed to autosave draft text."
  },
};

function formatSaveLabel(date: Date): string {
  const now = new Date();
  const isToday = date.toDateString() === now.toDateString();

  if (isToday) {
    // Time only for today: "Uloženo v 14:23" / "Saved at 14:23"
    const timeStr = date.toLocaleTimeString("cs-CZ", {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
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

export interface FolioTiptapAutosaveIndicatorProps extends ButtonProps {
  editor: Editor;
  autosaveIndicatorInfo?: FolioTiptapAutosaveIndicatorInfo;
}

export const FolioTiptapAutosaveIndicator = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapAutosaveIndicatorProps
>(({ editor, autosaveIndicatorInfo }, ref) => {
  const [lastSavedAt, setLastSavedAt] = React.useState<Date | null>(
    autosaveIndicatorInfo?.latestRevisionAt ? new Date(autosaveIndicatorInfo.latestRevisionAt) : null
  );
  const [hasUnsavedChanges, setHasUnsavedChanges] = React.useState<boolean>(autosaveIndicatorInfo?.hasUnsavedChanges ?? false);
  const [failedToAutosave, setFailedToAutosave] = React.useState<boolean>(false);

  const newRecord = autosaveIndicatorInfo?.newRecord ?? true;

  React.useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      if (event.data?.type === 'f-input-tiptap:autosave:auto-saved') {
        setLastSavedAt(new Date(event.data.updatedAt));
        setFailedToAutosave(false);
      } else if (event.data?.type === 'f-input-tiptap:autosave:continue-unsaved-changes') {
        setHasUnsavedChanges(false);
      } else if (event.data?.type === 'f-input-tiptap:autosave:failed-to-autosave') {
        setFailedToAutosave(true);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  const label = lastSavedAt
    ? formatSaveLabel(lastSavedAt)
    : translate(TRANSLATIONS, "saveAt");

  const getButtonState = () => {
    if (newRecord) {
      return {
        icon: <SaveOff className="tiptap-button-icon" color="#FF9A52" />,
        style: { pointerEvents: 'none' as const },
        'aria-label': undefined,
        tooltip: undefined,
      };
    }

    if (hasUnsavedChanges) {
      return {
        icon: <AlertTriangle className="tiptap-button-icon" color="#FF9A52" />,
        style: { pointerEvents: 'none' as const },
        'aria-label': undefined,
        tooltip: undefined,
      };
    }

    if (failedToAutosave) {
      const failedLabel = translate(TRANSLATIONS, "failedToAutosave");
      return {
        icon: <SaveOff className="tiptap-button-icon" color="#F0655D" />,
        style: { cursor: 'help' },
        'data-no-hover': 'true',
        'aria-label': failedLabel,
        tooltip: failedLabel,
      };
    }

    return {
      icon: <Save className="tiptap-button-icon" color="#00B594" />,
      style: { cursor: 'help' },
      'data-no-hover': 'true',
      'aria-label': label,
      tooltip: label,
    };
  };

  const buttonState = getButtonState();

  return (
    <Button
      ref={ref}
      type="button"
      data-style="ghost"
      role="button"
      tabIndex={-1}
      style={buttonState.style}
      data-no-hover={buttonState['data-no-hover']}
      aria-label={buttonState['aria-label']}
      tooltip={buttonState.tooltip}
    >
      {buttonState.icon}
    </Button>
  );
});

FolioTiptapAutosaveIndicator.displayName = "FolioTiptapAutosaveIndicator";

export default FolioTiptapAutosaveIndicator;
