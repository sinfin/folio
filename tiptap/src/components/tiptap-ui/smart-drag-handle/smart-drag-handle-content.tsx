import React, { useState, createElement } from "react";
import {
  ClipboardCopy,
  ClipboardPaste,
  GripVertical,
  Plus,
  Check,
} from "lucide-react";
import type { Editor } from "@tiptap/react";
import type { Node } from "@tiptap/pm/model";

import { Button } from "@/components/tiptap-ui-primitive/button";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuGroup,
} from "@/components/tiptap-ui-primitive/dropdown-menu";
import { CloseIcon, PencilBoxIcon } from "@/components/tiptap-icons";

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
  const rect = (event.target as HTMLElement)
    .closest(".drag-handle")!
    .getBoundingClientRect();

  const nodeToUse = findElementNextToCoords({
    x: rect.left,
    y: rect.top + 16,
    direction: "right",
    editor,
  });

  if (!nodeToUse || nodeToUse.resolvedPos === null) {
    console.error("No node found at the clicked position");
    return;
  }

  editor.chain().focus().triggerFolioTiptapCommand(nodeToUse.resolvedPos).run();
};

const handleDragClick = () => {};

type DragHandleButtonReturnType = {
  success: boolean;
  data?: { html?: string };
};

type TargetNodeInfo = {
  resultElement: Element | null;
  resultNode: Node | null;
  pos: number | null;
};

type ClipboardDataType = {
  at: number | null;
  html: string | null;
};

const getPosAtDepthOne = (
  editor: Editor,
  targetNode: TargetNodeInfo,
): { startPos: number; endPos: number } => {
  if (!targetNode.resultNode || targetNode.pos === null) {
    throw new Error("Invalid target node");
  }

  const resolvedPos = editor.state.doc.resolve(targetNode.pos);

  let startPos, endPos;

  if (
    targetNode.resultNode.isLeaf ||
    targetNode.resultNode.content.size === 0
  ) {
    startPos = targetNode.pos;
    endPos = targetNode.pos + targetNode.resultNode.nodeSize;
  } else {
    startPos = resolvedPos.before(1);
    endPos = resolvedPos.after(1);
  }

  return { startPos, endPos };
};

const copyNode = async (
  editor: Editor,
  targetNode: TargetNodeInfo,
  _: ClipboardDataType,
): Promise<DragHandleButtonReturnType> => {
  try {
    if (targetNode && targetNode.resultElement) {
      const html = targetNode.resultElement.outerHTML;
      const text = targetNode.resultElement.textContent || "";

      try {
        await navigator.clipboard.write([
          new ClipboardItem({
            "text/html": new Blob([html], { type: "text/html" }),
            "text/plain": new Blob([text], { type: "text/plain" }),
          }),
        ]);
      } catch (error) {
        console.error("Failed to write to clipboard:", error);
      }

      return { success: true, data: { html } };
    }

    console.error("No target node found for copying");
    return { success: false };
  } catch (error) {
    console.error("Error copying node:", error);
    return { success: false };
  }
};

const pasteNode = (
  editor: Editor,
  targetNode: TargetNodeInfo,
  clipboardData: ClipboardDataType,
): DragHandleButtonReturnType => {
  try {
    if (!clipboardData.html) {
      return { success: false };
    }

    const { startPos, endPos } = getPosAtDepthOne(editor, targetNode);

    // Check if the target node is an empty paragraph
    const isEmptyParagraph =
      targetNode.resultNode?.type.name === "paragraph" &&
      targetNode.resultNode.content.size === 0;

    if (isEmptyParagraph) {
      // Use TipTap's insertContentAt to properly parse and insert HTML
      editor.commands.insertContentAt(startPos, clipboardData.html);
    } else {
      // Insert after the current node
      // Use TipTap's insertContentAt to properly parse and insert HTML
      editor.commands.insertContentAt(endPos, clipboardData.html);
    }
    return { success: true };
  } catch (error) {
    console.error("Error pasting node:", error);
    return { success: false };
  }
};

const removeNode = (
  editor: Editor,
  targetNode: TargetNodeInfo,
  _: ClipboardDataType,
): DragHandleButtonReturnType => {
  try {
    const { startPos, endPos } = getPosAtDepthOne(editor, targetNode);

    if (typeof startPos === "number" && typeof endPos === "number") {
      const tr = editor.state.tr;
      tr.delete(startPos, endPos);
      editor.view.dispatch(tr);
      return { success: true };
    } else {
      console.error("Error removing node");
      return { success: false };
    }
  } catch (error) {
    console.error("Error removing node:", error);
    return { success: false };
  }
};

const editFolioTiptapNode = (
  editor: Editor,
  targetNode: TargetNodeInfo,
  _: ClipboardDataType,
): DragHandleButtonReturnType => {
  if (!targetNode.resultNode || targetNode.pos === null) {
    console.error("Invalid target node");
    return { success: false };
  }

  if (targetNode.resultElement) {
    const event = new CustomEvent("f-tiptap-node:edit");
    targetNode.resultElement.dispatchEvent(event);
    return { success: true };
  }

  return { success: false };
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

const DRAG_HANDLE_PASTE_OPTION = {
  type: "pasteNode",
  icon: ClipboardPaste,
  command: pasteNode,
};

const DRAG_HANDLE_FOLIO_TIPTAP_NODE_OPTION = {
  type: "editFolioTiptapNode",
  icon: PencilBoxIcon,
  command: editFolioTiptapNode,
};

const makeButtonOnClick =
  (
    editor: Editor,
    option: {
      type: string;
      command: (
        editor: Editor,
        nodeInfo: TargetNodeInfo,
        clipboardData: ClipboardDataType,
      ) => DragHandleButtonReturnType | Promise<DragHandleButtonReturnType>;
    },
    setOpenedDropdown: (value: string | null) => void,
    clipboardData: ClipboardDataType,
    setClipboardData: (data: {
      at: number | null;
      html: string | null;
    }) => void,
  ) =>
  async () => {
    const rect = document
      .querySelector(".f-tiptap-smart-drag-handle__button--drag")!
      .getBoundingClientRect();

    const nodeToUse = findElementNextToCoords({
      x: rect.left,
      y: rect.top + 16,
      direction: "right",
      editor,
    });

    if (nodeToUse && nodeToUse.resultNode && nodeToUse.pos !== null) {
      const { success, data } = await option.command(
        editor,
        nodeToUse,
        clipboardData,
      );

      if (success) {
        setOpenedDropdown(null);
        if (option.type === "copyNode") {
          if (data && data.html) {
            setClipboardData({ at: Date.now(), html: data.html });
          }
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
  clipboardData: ClipboardDataType;
  setClipboardData: (data: { at: number | null; html: string | null }) => void;
}

const CHECK_ICON_DURATION = 1000;

export function SmartDragHandleContent({
  editor,
  selectedNodeData,
  clipboardData,
  setClipboardData,
}: SmartDragHandleContentProps) {
  const [openedDropdown, setOpenedDropdown] = useState<string | null>(null);
  const [, forceUpdate] = React.useReducer((x) => x + 1, 0);
  const wrapRef = React.useRef<HTMLDivElement>(null);
  const [style] = React.useState<object | undefined>(undefined);

  // Force re-render after CHECK_ICON_DURATION seconds to swap icon back
  React.useEffect(() => {
    if (clipboardData.at) {
      const timeout = setTimeout(() => {
        forceUpdate();
      }, CHECK_ICON_DURATION);
      return () => clearTimeout(timeout);
    }
  }, [clipboardData.at]);

  if (!editor) {
    return null;
  }

  let optionsBase;

  if (clipboardData.at) {
    optionsBase = [
      ...DRAG_HANDLE_DROPDOWN_OPTIONS.slice(0, 1),
      DRAG_HANDLE_PASTE_OPTION,
      ...DRAG_HANDLE_DROPDOWN_OPTIONS.slice(1),
    ];
  } else {
    optionsBase = DRAG_HANDLE_DROPDOWN_OPTIONS;
  }

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
              {clipboardData.at &&
              Date.now() - clipboardData.at < CHECK_ICON_DURATION ? (
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
                    onClick={makeButtonOnClick(
                      editor,
                      option,
                      setOpenedDropdown,
                      clipboardData,
                      setClipboardData,
                    )}
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
