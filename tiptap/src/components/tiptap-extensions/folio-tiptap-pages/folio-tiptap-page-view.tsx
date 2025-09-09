import React, { useMemo } from 'react';
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from '@tiptap/react';
import { findChildren } from '@tiptap/core';
import { TextSelection } from '@tiptap/pm/state';
import { toggleFolioTiptapPageCollapsed } from './folio-tiptap-pages-utils';
import { MenuDownIcon, MenuUpIcon } from '@/components/tiptap-icons';

import translate from "@/lib/i18n";

const TRANSLATIONS = {
  cs: {
    missingHeading: "Chybí titulek stránky",
  },
  en: {
    missingHeading: "Missing page heading",
  },
}

interface FolioTiptapPageViewProps extends NodeViewProps {
  // Additional props can be added here if needed
}


const addHeadingToStartofPage = ({ editor, getPos }: { editor: any; getPos: () => number | undefined }) => {
  const pos = getPos();
  if (typeof pos !== 'number') return;

  // Create a level 2 heading node
  const headingNode = editor.schema.nodes.heading.create({ level: 2 });

  // Calculate position at the start of the page content
  const startOfPageContent = pos + 1;

  // Create transaction to insert the heading
  const tr = editor.state.tr;
  tr.insert(startOfPageContent, headingNode);

  // Set cursor inside the new heading
  const newCursorPos = startOfPageContent + 1;
  tr.setSelection(TextSelection.create(tr.doc, newCursorPos));

  // Dispatch the transaction
  editor.view.dispatch(tr);
}

const goToEndOfPage = ({ event, editor, getPos }: { event: React.MouseEvent; editor: any; getPos: () => number | undefined }) => {
  event.preventDefault()
  event.stopPropagation()

  const pos = getPos()

  if (typeof pos !== 'number') return false;

  // Shift by one as getPos() marks the beginning, not the inside
  const resolvedPos = editor.state.doc.resolve(pos + 1)
  const endPos = resolvedPos.end(resolvedPos.depth)
  const tr = editor.state.tr.setSelection(TextSelection.create(editor.state.doc, endPos - 1))
  editor.view.dispatch(tr)
}

export const FolioTiptapPageView: React.FC<FolioTiptapPageViewProps> = ({ node, getPos, editor }) => {
  if (!editor) return

  const headingNodes = useMemo(() => {
    return findChildren(node, (child) => child.type.name === 'heading');
  }, [node]);

  const filledHeadingNode = useMemo(() => {
    return headingNodes.find((child) => child.node.content.size > 0);
  }, [headingNodes]);

  const handleToggleCollapsed = () => {
    toggleFolioTiptapPageCollapsed({
      state: editor.state,
      dispatch: editor.view.dispatch,
      node,
      getPos,
    });
  };

  let className = "f-tiptap-page"

  const invalid = !filledHeadingNode

  // only show placeholder if it's invalid and there's not a single heading node present
  let showPlaceholder = headingNodes.length === 0

  if (invalid) {
    className += " f-tiptap-page--invalid"
  }

  if (node.attrs.collapsed) {
    className += " f-tiptap-page--collapsed"
  }

  return (
    <NodeViewWrapper className={className}>
      <div className="f-tiptap-page__toggle-wrap" onClick={handleToggleCollapsed}>
        <div className="f-tiptap-page__toggle">
          {node.attrs.collapsed ? <MenuDownIcon className="f-tiptap-page__toggle-ico" /> : <MenuUpIcon className="f-tiptap-page__toggle-ico" />}
        </div>
      </div>

      <div className="f-tiptap-page__content">
        {showPlaceholder ? <h2 className="f-tiptap-page__title-placeholder is-empty" data-placeholder={translate(TRANSLATIONS, 'missingHeading')} onClick={() => { addHeadingToStartofPage({ editor, getPos }) }}><br className="ProseMirror-trailingBreak" /></h2> : null}
        <NodeViewContent />
      </div>

      <span
        className="f-tiptap-page__content-click-trigger"
        onClick={(event) => goToEndOfPage({ event, editor, getPos })}
      />
    </NodeViewWrapper>
  );
};

export default FolioTiptapPageView;
