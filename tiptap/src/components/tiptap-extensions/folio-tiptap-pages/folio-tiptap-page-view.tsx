import React, { useMemo } from 'react';
import { NodeViewContent, NodeViewWrapper, NodeViewProps } from '@tiptap/react';
import { findParentNode, findChildren } from '@tiptap/core';
import { toggleFolioTiptapPageCollapsed } from './folio-tiptap-pages-utils';
import { MenuDownIcon, MenuUpIcon } from '@/components/tiptap-icons';

interface FolioTiptapPageViewProps extends NodeViewProps {
  // Additional props can be added here if needed
}

export const FolioTiptapPageView: React.FC<FolioTiptapPageViewProps> = ({ node, getPos, editor }) => {
  if (!editor) return

  const containsHeadingNodeWithContent = useMemo(() => {
    const children = findChildren(node, (child) => child.type.name === 'heading' && child.content.size > 0);
    return children.length > 0;
  }, [node]);

  const handleToggleCollapsed = () => {
    toggleFolioTiptapPageCollapsed({
      state: editor.state,
      dispatch: editor.view.dispatch,
      node,
      getPos,
    });
  };

  let className = "f-tiptap-page"

  if (!containsHeadingNodeWithContent) {
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
        <NodeViewContent />
      </div>
    </NodeViewWrapper>
  );
};

export default FolioTiptapPageView;
