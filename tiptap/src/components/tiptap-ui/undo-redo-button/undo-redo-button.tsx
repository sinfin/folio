import * as React from "react"
import { type Editor } from "@tiptap/react"

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor"

// --- Icons ---
import { Redo2Icon } from "@/components/tiptap-icons/redo2-icon"
import { Undo2Icon } from "@/components/tiptap-icons/undo2-icon"

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button"
import { Button } from "@/components/tiptap-ui-primitive/button"

export type HistoryAction = "undo" | "redo"

/**
 * Props for the UndoRedoButton component.
 */
export interface UndoRedoButtonProps extends ButtonProps {
  /**
   * The TipTap editor instance.
   */
  editor?: Editor | null
  /**
   * The history action to perform (undo or redo).
   */
  action: HistoryAction,
  enabled: boolean,
  active: boolean,
}

export const historyIcons = {
  undo: Undo2Icon,
  redo: Redo2Icon,
}

export const historyShortcutKeys: Partial<Record<HistoryAction, string>> = {
  undo: "Ctrl-z",
  redo: "Ctrl-Shift-z",
}

export const historyActionLabels: Record<HistoryAction, string> = {
  undo: "Undo",
  redo: "Redo",
}

/**
 * Executes a history action on the editor.
 *
 * @param editor The TipTap editor instance
 * @param action The history action to execute
 * @returns Whether the action was executed successfully
 */
export function executeHistoryAction(
  editor: Editor | null,
  action: HistoryAction
): boolean {
  if (!editor) return false
  const chain = editor.chain().focus()
  return action === "undo" ? chain.undo().run() : chain.redo().run()
}

/**
 * Button component for triggering undo/redo actions in a TipTap editor.
 */
export const UndoRedoButton = React.forwardRef<
  HTMLButtonElement,
  UndoRedoButtonProps
>(
  (
    {
      editor: providedEditor,
      action,
      className = "",
      active,
      enabled,
      children,
      ...buttonProps
    },
    ref
  ) => {
    const editor = useTiptapEditor(providedEditor)

    const handleAction = React.useCallback(() => {
      if (!editor || !enabled) return
      executeHistoryAction(editor, action)
    }, [editor, action, enabled])

    const Icon = historyIcons[action]
    const actionLabel = historyActionLabels[action]
    const shortcutKey = historyShortcutKeys[action]

    const handleClick = React.useCallback(
      (e: React.MouseEvent<HTMLButtonElement>) => {
        console.log('if', '!e.defaultPrevented:', !e.defaultPrevented, '!enabled:', !enabled)
        if (!e.defaultPrevented && enabled) {
          handleAction()
        }
      },
      [enabled, handleAction]
    )

    if (!editor || !editor.isEditable) {
      return null
    }

    return (
      <Button
        ref={ref}
        type="button"
        className={className.trim()}
        disabled={!enabled}
        data-style="ghost"
        data-disabled={!enabled}
        role="button"
        tabIndex={-1}
        aria-label={actionLabel}
        tooltip={actionLabel}
        shortcutKeys={shortcutKey}
        onClick={handleClick}
        {...buttonProps}
      >
        {children || (
          <>
            <Icon className="tiptap-button-icon" />
          </>
        )}
      </Button>
    )
  }
)

UndoRedoButton.displayName = "UndoRedoButton"

export default UndoRedoButton
