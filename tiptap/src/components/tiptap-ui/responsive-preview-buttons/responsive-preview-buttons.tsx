import * as React from "react"
import { MonitorIcon, SmartphoneIcon } from '@/components/tiptap-icons';
import translate from "@/lib/i18n";

import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";

import "./responsive-preview-buttons.scss"

const TRANSLATIONS = {
  cs: {
    mobile: "Mobilní layout",
    desktop: "Desktop layout",
  },
  en: {
    mobile: "Mobile layout",
    desktop: "Desktop layout",
  }
}

interface ResponsivePreviewButtonsProps {
  setResponsivePreviewWidth: (width: number | null) => void;
}

export const ResponsivePreviewButtons = ({ setResponsivePreviewWidth }: ResponsivePreviewButtonsProps) => {
  const mobileLabel = translate(TRANSLATIONS, "mobile");
  const desktopLabel = translate(TRANSLATIONS, "desktop");

  return (
    <div className='f-tiptap-editor-responsive-preview-buttons'>
      <Button
        type="button"
        data-style="ghost"
        role="button"
        tabIndex={-1}
        aria-label={mobileLabel}
        tooltip={mobileLabel}
        className="f-tiptap-editor-responsive-preview-buttons__button f-tiptap-editor-responsive-preview-buttons__button--mobile"
        onClick={(e) => { (e.target as HTMLElement).blur(); setResponsivePreviewWidth(480) }}
      >
        <SmartphoneIcon className="tiptap-button-icon" />
      </Button>
      <Button
        type="button"
        data-style="ghost"
        role="button"
        tabIndex={-1}
        aria-label={desktopLabel}
        tooltip={desktopLabel}
        className="f-tiptap-editor-responsive-preview-buttons__button f-tiptap-editor-responsive-preview-buttons__button--desktop"
        onClick={(e) => { (e.target as HTMLElement).blur(); setResponsivePreviewWidth(null) }}
      >
        <MonitorIcon className="tiptap-button-icon" />
      </Button>
    </div>
  )
}

ResponsivePreviewButtons.displayName = "ResponsivePreviewButtons"

export default ResponsivePreviewButtons
