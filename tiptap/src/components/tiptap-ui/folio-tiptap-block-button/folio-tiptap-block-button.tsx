"use client"

import * as React from "react"
import { type Editor } from "@tiptap/react"

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor"

// --- Icons ---
import { BlocksIcon } from "@/components/tiptap-icons/blocks-icon"

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button"
import { Button } from "@/components/tiptap-ui-primitive/button"

export interface FolioTiptapBlockButtonProps extends ButtonProps {
  editor?: Editor | null
  text?: string
  extensionName?: string
}

export function isFolioBlockActive(
  editor: Editor | null,
  extensionName: string
): boolean {
  if (!editor) return false
  return editor.isActive(extensionName)
}

export function insertFolioBlock(
  editor: Editor | null,
  extensionName: string
): boolean {
  if (!editor) {
    console.log('No editor available for insertFolioBlock')
    return false
  }

  console.log('Inserting FolioTiptapBlock using custom command')
  console.log('Available commands:', Object.keys(editor.commands))
  
  try {
    // Use the custom command defined in the extension
    const result = editor
      .chain()
      .focus()
      .setFolioTiptapBlock()
      .run()
    
    console.log('setFolioTiptapBlock result:', result)
    return result
  } catch (error) {
    console.error('Error inserting FolioTiptapBlock:', error)
    return false
  }
}

export function useFolioTiptapBlockButton(
  editor: Editor | null,
  extensionName: string = "folioTiptapBlock",
  disabled: boolean = false
) {
  const isActive = isFolioBlockActive(editor, extensionName)
  const handleInsertBlock = React.useCallback(() => {
    if (disabled) return false
    return insertFolioBlock(editor, extensionName)
  }, [editor, extensionName, disabled])

  return {
    isActive,
    handleInsertBlock,
  }
}

export const FolioTiptapBlockButton = React.forwardRef<
  HTMLButtonElement,
  FolioTiptapBlockButtonProps
>(
  (
    {
      editor: providedEditor,
      extensionName = "folioTiptapBlock",
      text,
      className = "",
      disabled,
      children,
      ...buttonProps
    },
    ref
  ) => {
    const editor = useTiptapEditor(providedEditor)
    const { isActive, handleInsertBlock } = useFolioTiptapBlockButton(
      editor,
      extensionName,
      disabled
    )

    const handleClick = React.useCallback(
      (e: React.MouseEvent<HTMLButtonElement>) => {
        console.log('FolioTiptapBlock button clicked!')
        console.log('Editor available:', !!editor)
        console.log('Editor editable:', editor?.isEditable)
        console.log('Disabled:', disabled)

        if (!e.defaultPrevented && !disabled) {
          window.top!.postMessage(
            {
              type: "f-tiptap:block:insert",
            },
            "*",
          );
        }
      },
      [disabled]
    )

    if (!editor || !editor.isEditable) {
      return null
    }

    return (
      <Button
        ref={ref}
        type="button"
        className={className.trim()}
        data-style="ghost"
        data-active-state={isActive ? "on" : "off"}
        role="button"
        tabIndex={-1}
        aria-label="Add Folio Block"
        aria-pressed={isActive}
        tooltip="Add Folio Block"
        onClick={handleClick}
        {...buttonProps}
      >
        {children || (
          <>
            <BlocksIcon className="tiptap-button-icon" />
            {text && <span className="tiptap-button-text">{text}</span>}
          </>
        )}
      </Button>
    )
  }
)

FolioTiptapBlockButton.displayName = "FolioTiptapBlockButton"

export default FolioTiptapBlockButton
