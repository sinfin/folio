import * as React from "react";

import { debounce } from "@/lib/debounce";
import { ArrowSplitVerticalIcon } from "@/components/tiptap-icons";

import "./folio-editor-responsive-preview.scss";

interface FolioEditorResponsivePreviewProps {
  enabled: boolean;
  children: React.ReactNode;
  shouldScrollToInitial: number | null;
  setShouldScrollToInitial: (value: null) => void;
}

const MINIMUM_WIDTH = 375;

export function FolioEditorResponsivePreview({
  enabled,
  shouldScrollToInitial,
  setShouldScrollToInitial,
  children,
}: FolioEditorResponsivePreviewProps) {
  const [responsivePreviewWidth, setResponsivePreviewWidth] =
    React.useState<number>(MINIMUM_WIDTH);
  const scrollRef = React.useRef<HTMLDivElement>(null);

  const onMouseDown = React.useCallback(
    (event: React.MouseEvent<HTMLDivElement>) => {
      event.preventDefault();
      event.stopPropagation();

      const startX = event.clientX;
      const startWidth = responsivePreviewWidth;

      const onMouseMove = (moveEvent: MouseEvent) => {
        const newWidth = Math.max(
          startWidth + 2 * (moveEvent.clientX - startX),
          MINIMUM_WIDTH,
        );
        const cappedNewWidth = Math.min(window.innerWidth - 36, newWidth);
        setResponsivePreviewWidth(cappedNewWidth);
      };

      const onMouseUp = () => {
        document.removeEventListener("mousemove", onMouseMove);
        document.removeEventListener("mouseup", onMouseUp);
      };

      document.addEventListener("mousemove", onMouseMove);
      document.addEventListener("mouseup", onMouseUp);
    },
    [responsivePreviewWidth],
  );

  // scroll to initial position
  React.useEffect(() => {
    if (shouldScrollToInitial !== null && scrollRef.current) {
      setShouldScrollToInitial(null);
      window.setTimeout(() => {
        if (scrollRef.current) {
          scrollRef.current.scrollTop = shouldScrollToInitial;
        }
      }, 0);
    }
  }, [shouldScrollToInitial, setShouldScrollToInitial]);

  // debounced onScroll
  const onScroll = React.useMemo(
    () =>
      debounce(() => {
        if (scrollRef.current) {
          window.parent!.postMessage(
            {
              type: "f-tiptap-editor:scrolled",
              scrollTop: scrollRef.current.scrollTop,
            },
            "*",
          );
        }
      }),
    [],
  );

  return (
    <div className="f-tiptap-editor-responsive-preview">
      <div
        className="f-tiptap-editor-responsive-preview__scroll"
        ref={scrollRef}
        onScroll={onScroll}
      >
        <div
          className="f-tiptap-editor-responsive-preview__inner"
          style={{
            width:
              enabled && responsivePreviewWidth
                ? `${responsivePreviewWidth}px`
                : "auto",
          }}
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
  );
}
