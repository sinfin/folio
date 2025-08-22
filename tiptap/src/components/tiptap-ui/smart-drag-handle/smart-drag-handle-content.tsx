import React, { useState, createElement } from "react";
import {
  ClipboardCopy,
  ClipboardPaste,
  GripVertical,
  Plus,
  Check
} from "lucide-react";
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
  const rect = (event.target as HTMLElement).closest('.drag-handle')!.getBoundingClientRect();

  const nodeToUse = findElementNextToCoords({
    x: rect.left,
    y: rect.top,
    direction: "right",
    editor,
  });

  if (!nodeToUse || nodeToUse.resolvedPos === null) {
    console.error("No node found at the clicked position");
    return;
  }

  editor
    .chain()
    .focus()
    .triggerFolioTiptapCommand(nodeToUse.resolvedPos)
    .run();
};

const handleDragClick = () => {};

type TargetNodeInfo = {
  resultElement: Element | null;
  resultNode: Node | null;
  pos: number | null;
};

const getPosAtDepthOne = (editor: Editor, targetNode: TargetNodeInfo): { startPos: number, endPos: number } => {
  if (!targetNode.resultNode || targetNode.pos === null) {
    throw new Error("Invalid target node");
  }

  const resolvedPos = editor.state.doc.resolve(targetNode.pos);

  let startPos, endPos

  if (targetNode.resultNode.isLeaf || targetNode.resultNode.content.size === 0) {
    startPos = targetNode.pos
    endPos = targetNode.pos + targetNode.resultNode.nodeSize;
  } else {
    startPos = resolvedPos.before(1);
    endPos = resolvedPos.after(1);
  }

  return { startPos, endPos }
}

const copyNode = async (editor: Editor, targetNode: TargetNodeInfo): Promise<boolean> => {
  try {
    await navigator.clipboard.write([
      new ClipboardItem({
        'text/html': new Blob([targetNode.resultElement.outerHTML], { type: 'text/html' }),
        'text/plain': new Blob([targetNode.resultElement.textContent], { type: 'text/plain' }),
      })
    ]);

    return true;
  } catch (error) {
    console.error("Error copying node:", error);
    return false;
  }
}

const pasteNode = (editor: Editor, targetNode: TargetNodeInfo): boolean => {
  console.log('pasteNode')
  return false
}

const removeNode = (editor: Editor, targetNode: TargetNodeInfo): boolean => {
  try {
    const { startPos, endPos } = getPosAtDepthOne(editor, targetNode)

    if (typeof startPos === "number" && typeof endPos === "number") {
      const tr = editor.state.tr;
      tr.delete(startPos, endPos);
      editor.view.dispatch(tr);
      return true;
    } else {
      console.error("Error removing node");
      return false;
    }
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
    copyNode: "Kopírovat",
    pasteNode: "Vložit",
    removeNode: "Odstranit",
    editFolioTiptapNode: "Upravit",
  },
  en: {
    copyNode: "Copy",
    pasteNode: "Paste",
    removeNode: "Remove",
    editFolioTiptapNode: "Edit",
  },
};

const DRAG_HANDLE_DROPDOWN_OPTIONS = [
  {
    type: "copyNode",
    icon: ClipboardCopy,
    command: copyNode,
  },
  {
    type: "removeNode",
    icon: CloseIcon,
    command: removeNode,
  },
];

const DRAG_HANDLE_EMPTY_PARAGRAPH_OPTION = {
  type: "pasteNode",
  icon: ClipboardPaste,
  command: pasteNode,
}

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
    setCopiedToClipboardAt: (at: number) => void,
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
        if (option.type === "copyNode") {
          setCopiedToClipboardAt(Date.now());
        }
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
  copiedToClipboardAt: number | null;
  setCopiedToClipboardAt: (at: number) => void;
}

const CHECK_ICON_DURATION = 1000

export function SmartDragHandleContent({
  editor,
  selectedNodeData,
  copiedToClipboardAt,
  setCopiedToClipboardAt,
}: SmartDragHandleContentProps) {
  const [openedDropdown, setOpenedDropdown] = useState<string | null>(null);

  const [, forceUpdate] = React.useReducer(x => x + 1, 0);

  // Force re-render after CHECK_ICON_DURATION seconds to swap icon back
  React.useEffect(() => {
    if (copiedToClipboardAt) {
      const timeout = setTimeout(() => {
        forceUpdate();
      }, CHECK_ICON_DURATION);
      return () => clearTimeout(timeout);
    }
  }, [copiedToClipboardAt]);

  if (!editor) {
    return null;
  }

  const wrapRef = React.useRef<HTMLDivElement>(null);
  const [style, setStyle] = React.useState<object | undefined>(undefined);

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
      if (nodeHeight) {
        if (nodeHeight < 32) {
          return setStyle({ transform: `translate(0, -${(32 - nodeHeight) / 2}px)` });
        } else {
          return setStyle({ minHeight: `${nodeHeight}px` });
        }
      }
    }

    return setStyle(undefined);
  }, [
    selectedNodeData && selectedNodeData.y,
    setStyle,
    editor,
    wrapRef && wrapRef.current,
  ]);

  const optionsBase = DRAG_HANDLE_DROPDOWN_OPTIONS

  const dragHandleButtonOptions = [
    ...(selectedNodeData && selectedNodeData.type === "folioTiptapNode"
      ? [
          ...optionsBase.slice(0, optionsBase.length - 1),
          DRAG_HANDLE_FOLIO_TIPTAP_NODE_OPTION,
          optionsBase[optionsBase.length - 1],
        ]
      : optionsBase),
  ];

  return (
    <div
      className="f-tiptap-smart-drag-handle-content"
      style={style}
      ref={wrapRef}
    >
      <div className="f-tiptap-smart-drag-handle-content__flex">
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
              {copiedToClipboardAt && Date.now() - copiedToClipboardAt < CHECK_ICON_DURATION ? (
                <Check className="tiptap-button-icon" />
              ) : (
                <GripVertical className="tiptap-button-icon" />
              )}
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
                    onClick={makeButtonOnClick(editor, option, setOpenedDropdown, setCopiedToClipboardAt)}
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
    </div>
  );
}
