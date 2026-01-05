import * as React from "react";
import {
  autoUpdate,
  FloatingPortal,
  offset,
  size,
  useFloating,
  useInteractions,
} from "@floating-ui/react";
import { type Editor } from "@tiptap/core";
import { TextSelection } from "@tiptap/pm/state";
import { Plus } from "lucide-react";
import translate from "@/lib/i18n";
import "./paragraph-placeholder.scss";

const TRANSLATIONS = {
  cs: {
    placeholder: "Klikněte pro přidání dalšího obsahu",
  },
  en: {
    placeholder: "Click to add more content",
  },
};

interface HasParagraphPlaceholderProps {
  children: React.ReactNode;
  editor: Editor;
  getPos?: () => number | undefined;
  target: string; // Kept for potential future use
  wrapperRef?: React.RefObject<HTMLElement>;
}

export const HasParagraphPlaceholder: React.FC<
  HasParagraphPlaceholderProps
> = ({ children, editor, getPos, target: _target, wrapperRef }) => {
  const [isHovered, setIsHovered] = React.useState(false);
  const [shouldShow, setShouldShow] = React.useState(false);
  const contentRef = React.useRef<HTMLDivElement>(null);
  const floatingRef = React.useRef<HTMLDivElement>(null);

  // Check if conditions are met (has div as last child in [data-node-view-content-react])
  // The wrapper component is already placed only on nodes that should have placeholders,
  // so we just need to check if the last child is a div (paragraph or other block element)
  // For pages, also check that page is not collapsed
  const checkConditions = React.useCallback(() => {
    if (!contentRef.current) return false;

    // Check if page is collapsed (for page target)
    const pageElement = contentRef.current.closest(".f-tiptap-page");
    if (pageElement?.classList.contains("f-tiptap-page--collapsed")) {
      return false;
    }

    // Find [data-node-view-content-react] - it might be a direct child or nested
    const nodeViewContent =
      contentRef.current.querySelector("[data-node-view-content-react]") ||
      contentRef.current;

    if (!nodeViewContent) return false;

    // Check if the last child is a div (paragraph, heading, etc.)
    const lastChild = nodeViewContent.lastElementChild;
    if (!lastChild) return false;

    return lastChild.tagName.toLowerCase() === "div";
  }, []);

  // Floating UI setup - position at bottom of content
  const { refs, floatingStyles } = useFloating({
    open: shouldShow,
    placement: "bottom",
    middleware: [
      offset({
        mainAxis: 0,
      }),
      size({
        apply({ rects, elements }) {
          // Match the width of the placeholder to the reference element
          Object.assign(elements.floating.style, {
            width: `${rects.reference.width}px`,
          });
        },
      }),
    ],
    whileElementsMounted: autoUpdate,
    strategy: "fixed",
  });

  const { getFloatingProps } = useInteractions([]);

  // Handle mouseenter - use mouseover to catch events from child elements
  const handleMouseEnter = React.useCallback((e: React.MouseEvent) => {
    // Only set hovered if the event target is within our content area
    if (contentRef.current?.contains(e.target as Node)) {
      setIsHovered(true);
    }
  }, []);

  // Handle mouseleave from wrapper - don't hide if mouse is moving to the placeholder
  const handleWrapperMouseLeave = React.useCallback((e: React.MouseEvent) => {
    const relatedTarget = e.relatedTarget;
    // Don't hide if mouse is moving to the placeholder element
    if (
      floatingRef.current &&
      relatedTarget &&
      relatedTarget instanceof Node &&
      (floatingRef.current.contains(relatedTarget) ||
        floatingRef.current === relatedTarget)
    ) {
      return;
    }
    setIsHovered(false);
  }, []);

  // Handle mouseleave from placeholder - always hide when leaving the placeholder
  const handlePlaceholderMouseLeave = React.useCallback(() => {
    setIsHovered(false);
  }, []);

  // Subscribe to editor updates only when hovering
  React.useEffect(() => {
    if (!editor || !isHovered) return;

    const handleUpdate = () => {
      const conditionsMet = checkConditions();
      if (conditionsMet) {
        setShouldShow(true);
        if (contentRef.current) {
          refs.setReference(contentRef.current);
        }
      } else {
        setShouldShow(false);
      }
    };

    editor.on("update", handleUpdate);

    return () => {
      editor.off("update", handleUpdate);
    };
  }, [editor, isHovered, checkConditions, refs]);

  // Update shouldShow when hover state or conditions change
  React.useEffect(() => {
    if (isHovered) {
      const conditionsMet = checkConditions();
      if (conditionsMet) {
        setShouldShow(true);
        // Set reference element for Floating UI - use the content container
        // We'll position at the bottom of the content area
        if (contentRef.current) {
          refs.setReference(contentRef.current);
        }
      } else {
        setShouldShow(false);
      }
    } else {
      setShouldShow(false);
    }
  }, [isHovered, checkConditions, refs]);

  // Handle placeholder click
  const handlePlaceholderClick = React.useCallback(() => {
    // Hide placeholder immediately
    setShouldShow(false);

    if (getPos) {
      const pos = getPos();
      if (typeof pos === "number") {
        // Insert at the end of the parent node
        const resolvedPos = editor.state.doc.resolve(pos + 1);
        const endPos = resolvedPos.end(resolvedPos.depth);
        const paragraphNode = editor.schema.nodes.paragraph.create();

        const tr = editor.state.tr;
        tr.insert(endPos, paragraphNode);

        // Set cursor in the new paragraph
        const newCursorPos = endPos + 1;
        tr.setSelection(TextSelection.create(tr.doc, newCursorPos));

        editor.view.dispatch(tr);
        // Focus the editor after inserting the paragraph
        editor.view.focus();
        return;
      }
    }

    // Fallback to current behavior if no getPos provided
    editor.chain().focus().insertContent({ type: "paragraph" }).run();
  }, [editor, getPos]);

  if (!editor || !editor.isEditable) {
    return <>{children}</>;
  }

  return (
    <>
      <div
        ref={(node) => {
          contentRef.current = node;
          if (wrapperRef && "current" in wrapperRef) {
            (wrapperRef as React.MutableRefObject<HTMLElement | null>).current =
              node;
          }
        }}
        onMouseEnter={handleMouseEnter}
        onMouseLeave={handleWrapperMouseLeave}
        onMouseOver={handleMouseEnter}
        style={{ position: "relative" }}
      >
        {children}
      </div>
      {shouldShow && (
        <FloatingPortal>
          <div
            ref={(node) => {
              floatingRef.current = node;
              refs.setFloating(node);
            }}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={handlePlaceholderMouseLeave}
            style={{
              ...floatingStyles,
              marginTop: 0,
            }}
            {...getFloatingProps()}
            className="f-tiptap-paragraph-placeholder"
          >
            <div
              className="f-tiptap-paragraph-placeholder__div"
              onClick={handlePlaceholderClick}
            >
              <Plus className="f-tiptap-paragraph-placeholder__icon" />
              {translate(TRANSLATIONS, "placeholder")}
            </div>
          </div>
        </FloatingPortal>
      )}
    </>
  );
};

HasParagraphPlaceholder.displayName = "HasParagraphPlaceholder";

export default HasParagraphPlaceholder;
