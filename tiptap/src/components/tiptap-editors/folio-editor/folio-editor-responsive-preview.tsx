import * as React from "react";

import { ArrowSplitVerticalIcon } from '@/components/tiptap-icons';

import "./folio-editor-responsive-preview.scss"

interface FolioEditorResponsivePreviewProps {
  enabled: boolean;
  children: React.ReactNode;
}

const MINIMUM_WIDTH = 375;

export function FolioEditorResponsivePreview({
  enabled,
  children,
}: FolioEditorResponsivePreviewProps) {
  const [responsivePreviewWidth, setResponsivePreviewWidth] = React.useState<number>(MINIMUM_WIDTH)

  const onMouseDown = React.useCallback((event: React.MouseEvent<HTMLDivElement>) => {
    event.preventDefault();
    event.stopPropagation();

    const startX = event.clientX;
    const startWidth = responsivePreviewWidth

    const onMouseMove = (moveEvent: MouseEvent) => {
      const newWidth = Math.max(startWidth + 2 * (moveEvent.clientX - startX), MINIMUM_WIDTH)
      const cappedNewWidth = Math.min(window.innerWidth - 36, newWidth)
      setResponsivePreviewWidth(cappedNewWidth);
    };

    const onMouseUp = () => {
      console.log('onMouseUp')
      document.removeEventListener("mousemove", onMouseMove);
      document.removeEventListener("mouseup", onMouseUp);
    };

    document.addEventListener("mousemove", onMouseMove);
    document.addEventListener("mouseup", onMouseUp);
  }, [enabled, responsivePreviewWidth]);

  return (
    <div className="f-tiptap-editor-responsive-preview">
      <div className="f-tiptap-editor-responsive-preview__scroll">
        <div
          className="f-tiptap-editor-responsive-preview__inner"
          style={{ width: (enabled && responsivePreviewWidth) ? `${responsivePreviewWidth}px` : "auto" }}
        >
          {children}
        </div>
      </div>

      {enabled ? (
        <div
          className="f-tiptap-editor-responsive-preview__handle"
          style={{ left: `calc(50% + ${responsivePreviewWidth / 2 - 18}px)` }}
          onMouseDown={onMouseDown}
        >
          <div className="f-tiptap-editor-responsive-preview__handle-flex">
            <div className="f-tiptap-editor-responsive-preview__handle-icon-wrap">
              <ArrowSplitVerticalIcon />
            </div>

            <div className="f-tiptap-editor-responsive-preview__handle-text">
              {`${responsivePreviewWidth}px`}
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
