import * as React from "react";
import translate from "@/lib/i18n";
import { type Editor } from "@tiptap/core";
import { TextSelection } from "@tiptap/pm/state";

import "./paragraph-placeholder.scss";

const TRANSLATIONS = {
  cs: {
    placeholder: "Klikněte pro přidání dalšího obsahu",
  },
  en: {
    placeholder: "Click to add more content",
  },
};

export const ParagraphPlaceholder = ({
  editor,
  getPos,
  target,
}: {
  editor: Editor;
  getPos?: () => number | undefined;
  target: string;
}) => {
  const onClick = React.useCallback(() => {
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
        return;
      }
    }

    // Fallback to current behavior if no getPos provided
    editor.chain().focus().insertContent({ type: "paragraph" }).run();
  }, [editor, getPos]);

  if (!editor || !editor.isEditable) return null;

  return (
    <p
      className={`f-tiptap-paragraph-placeholder f-tiptap-paragraph-placeholder--target-${target}`}
      onClick={onClick}
    >
      {translate(TRANSLATIONS, "placeholder")}
    </p>
  );
};

ParagraphPlaceholder.displayName = "ParagraphPlaceholder";

export default ParagraphPlaceholder;
