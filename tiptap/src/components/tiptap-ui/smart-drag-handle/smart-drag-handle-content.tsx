import React, { useState, createElement } from "react";
import { GripVertical, Plus } from "lucide-react";
import type { Editor } from "@tiptap/react";
import type { Node } from "@tiptap/pm/model";
import { TextSelection } from "@tiptap/pm/state";

import { Button } from "@/components/tiptap-ui-primitive/button";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuGroup,
} from "@/components/tiptap-ui-primitive/dropdown-menu";
import { CloseIcon, PencilBoxIcon } from '@/components/tiptap-icons';

import translate from "@/lib/i18n";

import { findElementNextToCoords } from "./smart-drag-handle-utils";
import "./smart-drag-handle-content.scss";

const handlePlusClick = ({
  event,
  editor,
}: {
  event: React.MouseEvent;
  editor: Editor;
}) => {
  const rect = (event.target as HTMLElement).getBoundingClientRect();

  const nodeToUse = findElementNextToCoords({
    x: rect.left,
    y: rect.top,
    direction: "right",
    editor,
  });

  if (!nodeToUse || nodeToUse.pos === null) {
    console.error("No node found at the clicked position");
    return;
  }

  editor
    .chain()
    .focus()
    .triggerFolioTiptapCommand(nodeToUse.pos)
    .run();
};

const handleDragClick = () => {};

type TargetNodeInfo = {
  resultElement: Element | null;
  resultNode: Node | null;
  pos: number | null;
};

const removeNode = (editor: Editor, targetNode: TargetNodeInfo): boolean => {
  try {
    const { state } = editor;

    if (!targetNode.resultNode || targetNode.pos === null) {
      console.error("Invalid target node");
      return false;
    }

    const resolvedPos = state.doc.resolve(targetNode.pos);
    const tr = state.tr;

    let startPos, endPos

    if (targetNode.resultNode.isLeaf || targetNode.resultNode.content.size === 0) {
      startPos = targetNode.pos
      endPos = targetNode.pos + targetNode.resultNode.nodeSize;
    } else {
      startPos = resolvedPos.before(1);
      endPos = resolvedPos.after(1);
    }

    tr.delete(startPos, endPos);
    editor.view.dispatch(tr);

    return true;
  } catch (error) {
    console.error("Error removing node:", error);
    return false;
  }
};

const editFolioTiptapNode = (
  editor: Editor,
  targetNode: TargetNodeInfo,
): boolean => {
  if (!targetNode.resultNode || targetNode.pos === null) {
    console.error("Invalid target node");
    return false;
  }

  if (targetNode.resultElement) {
    const event = new CustomEvent("f-tiptap-node:edit");
    targetNode.resultElement.dispatchEvent(event);
    return true;
  }

  return false;
};

const TRANSLATIONS = {
  cs: {
    removeNode: "Odstranit",
    editFolioTiptapNode: "Upravit",
  },
  en: {
    removeNode: "Remove",
    editFolioTiptapNode: "Edit",
  },
};

const DRAG_HANDLE_DROPDOWN_OPTIONS = [
  {
    type: "removeNode",
    icon: CloseIcon,
    command: removeNode,
  },
];

const DRAG_HANDLE_FOLIO_TIPTAP_NODE_OPTION = {
  type: "editFolioTiptapNode",
  icon: PencilBoxIcon,
  command: editFolioTiptapNode,
};

const makeButtonOnClick =
  (
    editor: Editor,
    option: { command: (editor: Editor, nodeInfo: TargetNodeInfo) => boolean },
    setOpenedDropdown: (value: string | null) => void,
  ) =>
  (e: React.MouseEvent) => {
    const rect = document
      .querySelector(".f-tiptap-smart-drag-handle__button--drag")!
      .getBoundingClientRect();

    const nodeToUse = findElementNextToCoords({
      x: rect.left,
      y: rect.top,
      direction: "right",
      editor,
    });

    if (nodeToUse && nodeToUse.resultNode && nodeToUse.pos !== null) {
      const success = option.command(editor, nodeToUse);

      if (success) {
        setOpenedDropdown(null);
      }
    } else {
      setOpenedDropdown(null);
    }
  };

export interface SmartDragHandleContentProps {
  /**
   * The TipTap editor instance.
   */
  editor: Editor | null;
  selectedNodeData: {
    type: string;
    x: number;
    y: number;
  } | null;
}

export function SmartDragHandleContent({
  editor,
  selectedNodeData,
}: SmartDragHandleContentProps) {
  const [openedDropdown, setOpenedDropdown] = useState<string | null>(null);

  if (!editor) {
    return null;
  }

  const wrapRef = React.useRef<HTMLDivElement>(null);
  const [nodeHeightPx, setNodeHeightPx] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (!wrapRef || !wrapRef.current || !editor) return;
    if (!selectedNodeData || !selectedNodeData.y) return;

    // y changed -> other node -> close
    if (openedDropdown) {
      setOpenedDropdown(null);
    }

    const nodeToUse = findElementNextToCoords({
      x: selectedNodeData.x,
      y: selectedNodeData.y,
      direction: "right",
      editor,
    });

    if (nodeToUse && nodeToUse.resultElement) {
      const nodeHeight = nodeToUse.resultElement.getBoundingClientRect().height;
      return setNodeHeightPx(`${nodeHeight}px`);
    }

    return setNodeHeightPx(null);
  }, [
    selectedNodeData && selectedNodeData.y,
    setNodeHeightPx,
    editor,
    wrapRef && wrapRef.current,
  ]);

  const dragHandleButtonOptions = [
    ...(selectedNodeData && selectedNodeData.type === "folioTiptapNode"
      ? [
          ...DRAG_HANDLE_DROPDOWN_OPTIONS.slice(
            0,
            DRAG_HANDLE_DROPDOWN_OPTIONS.length - 1,
          ),
          DRAG_HANDLE_FOLIO_TIPTAP_NODE_OPTION,
          DRAG_HANDLE_DROPDOWN_OPTIONS[DRAG_HANDLE_DROPDOWN_OPTIONS.length - 1],
        ]
      : DRAG_HANDLE_DROPDOWN_OPTIONS),
  ];

  return (
    <div
      className="f-tiptap-smart-drag-handle-content"
      style={{ minHeight: nodeHeightPx || undefined }}
      ref={wrapRef}
    >
      <Button
        type="button"
        data-style="ghost"
        role="button"
        tabIndex={-1}
        aria-label="Plus"
        onClick={(event) => {
          handlePlusClick({ event, editor });
        }}
        className="f-tiptap-smart-drag-handle__button f-tiptap-smart-drag-handle__button--plus"
      >
        <Plus className="tiptap-button-icon" />
      </Button>

      <DropdownMenu
        open={openedDropdown === "drag"}
        onOpenChange={(open: boolean) => {
          setOpenedDropdown(open ? "drag" : null);
        }}
      >
        <DropdownMenuTrigger asChild>
          <Button
            spanTag
            type="button"
            data-style="ghost"
            role="button"
            tabIndex={-1}
            aria-label="Drag"
            onClick={handleDragClick}
            className="f-tiptap-smart-drag-handle__button f-tiptap-smart-drag-handle__button--drag"
          >
            <GripVertical className="tiptap-button-icon" />
          </Button>
        </DropdownMenuTrigger>

        <DropdownMenuContent>
          <DropdownMenuGroup>
            {dragHandleButtonOptions.map((option) => (
              <DropdownMenuItem key={option.type} asChild>
                <Button
                  type="button"
                  data-style="ghost"
                  role="button"
                  tabIndex={-1}
                  aria-label={translate(TRANSLATIONS, option.type)}
                  className="f-tiptap-smart-drag-handle__dropdown-button"
                  onClick={makeButtonOnClick(editor, option, setOpenedDropdown)}
                >
                  {createElement(option.icon, {
                    className: "tiptap-button-icon",
                  })}
                  {translate(TRANSLATIONS, option.type)}
                </Button>
              </DropdownMenuItem>
            ))}
          </DropdownMenuGroup>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  );
}
