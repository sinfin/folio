import * as React from "react"
import type { FolioTiptapBlockAttributes } from "./folio-tiptap-block-extension"

// --- UI Primitives ---
import { Button } from "@/components/tiptap-ui-primitive/button"
import { Separator } from "@/components/tiptap-ui-primitive/separator"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/tiptap-ui-primitive/popover"

// --- Icons ---
import { SettingsIcon } from "@/components/tiptap-icons/settings-icon"
import { CheckIcon } from "@/components/tiptap-icons/check-icon"
import { XIcon } from "@/components/tiptap-icons/x-icon"

// --- Styles ---
import "./folio-tiptap-block-dialog.scss"

export interface FolioTiptapBlockDialogProps {
  isOpen: boolean
  onOpenChange: (open: boolean) => void
  attributes: FolioTiptapBlockAttributes
  onSave: (attributes: FolioTiptapBlockAttributes) => void
  onCancel: () => void
  children?: React.ReactNode
}

export interface FolioTiptapBlockDialogContentProps {
  attributes: FolioTiptapBlockAttributes
  onSave: (attributes: FolioTiptapBlockAttributes) => void
  onCancel: () => void
}

const FolioTiptapBlockDialogContent: React.FC<FolioTiptapBlockDialogContentProps> = ({
  attributes,
  onSave,
  onCancel,
}) => {
  const [title, setTitle] = React.useState(attributes.title || '')
  const [content, setContent] = React.useState(attributes.content || '')
  const [blockType, setBlockType] = React.useState(attributes.blockType || '')
  const [apiUrl, setApiUrl] = React.useState(attributes.apiUrl || '/api/folio-blocks')

  React.useEffect(() => {
    setTitle(attributes.title || '')
    setContent(attributes.content || '')
    setBlockType(attributes.blockType || '')
    setApiUrl(attributes.apiUrl || '/api/folio-blocks')
  }, [attributes])

  const handleSave = () => {
    onSave({
      title: title.trim(),
      content: content.trim(),
      blockType: blockType.trim(),
      apiUrl: apiUrl.trim(),
    })
  }

  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      handleSave()
    } else if (event.key === "Escape") {
      event.preventDefault()
      onCancel()
    }
  }

  const isValid = title.trim().length > 0 && blockType.trim().length > 0

  return (
    <div className="folio-tiptap-block-dialog-content">
      <div className="folio-tiptap-block-dialog-header">
        <h3 className="folio-tiptap-block-dialog-title">Configure Folio Block</h3>
      </div>

      <div className="folio-tiptap-block-dialog-body">
        <div className="folio-tiptap-block-dialog-field">
          <label htmlFor="folio-block-title" className="folio-tiptap-block-dialog-label">
            Title *
          </label>
          <input
            id="folio-block-title"
            type="text"
            placeholder="Enter block title..."
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            onKeyDown={handleKeyDown}
            className="tiptap-input"
            autoFocus
          />
        </div>

        <div className="folio-tiptap-block-dialog-field">
          <label htmlFor="folio-block-type" className="folio-tiptap-block-dialog-label">
            Block Type *
          </label>
          <select
            id="folio-block-type"
            value={blockType}
            onChange={(e) => setBlockType(e.target.value)}
            onKeyDown={handleKeyDown}
            className="tiptap-input"
          >
            <option value="">Select block type...</option>
            <option value="hero">Hero Section</option>
            <option value="gallery">Image Gallery</option>
            <option value="testimonial">Testimonial</option>
            <option value="cta">Call to Action</option>
            <option value="feature">Feature Block</option>
            <option value="custom">Custom Block</option>
          </select>
        </div>

        <div className="folio-tiptap-block-dialog-field">
          <label htmlFor="folio-block-content" className="folio-tiptap-block-dialog-label">
            Content
          </label>
          <textarea
            id="folio-block-content"
            placeholder="Enter block content or configuration..."
            value={content}
            onChange={(e) => setContent(e.target.value)}
            onKeyDown={handleKeyDown}
            className="tiptap-input folio-tiptap-block-dialog-textarea"
            rows={4}
          />
        </div>

        <div className="folio-tiptap-block-dialog-field">
          <label htmlFor="folio-block-api-url" className="folio-tiptap-block-dialog-label">
            API URL
          </label>
          <input
            id="folio-block-api-url"
            type="url"
            placeholder="/api/folio-blocks"
            value={apiUrl}
            onChange={(e) => setApiUrl(e.target.value)}
            onKeyDown={handleKeyDown}
            className="tiptap-input"
          />
        </div>
      </div>

      <Separator />

      <div className="folio-tiptap-block-dialog-footer">
        <div className="tiptap-button-group" data-orientation="horizontal">
          <Button
            type="button"
            onClick={onCancel}
            data-style="ghost"
            title="Cancel"
          >
            <XIcon className="tiptap-button-icon" />
            Cancel
          </Button>

          <Button
            type="button"
            onClick={handleSave}
            disabled={!isValid}
            data-style="primary"
            title="Save block (Ctrl/Cmd + Enter)"
          >
            <CheckIcon className="tiptap-button-icon" />
            Save Block
          </Button>
        </div>
      </div>
    </div>
  )
}

export const FolioTiptapBlockDialog: React.FC<FolioTiptapBlockDialogProps> = ({
  isOpen,
  onOpenChange,
  attributes,
  onSave,
  onCancel,
  children,
}) => {
  const handleSave = (newAttributes: FolioTiptapBlockAttributes) => {
    onSave(newAttributes)
    onOpenChange(false)
  }

  const handleCancel = () => {
    onCancel()
    onOpenChange(false)
  }

  return (
    <Popover open={isOpen} onOpenChange={onOpenChange}>
      <PopoverTrigger asChild>
        {children || (
          <Button data-style="ghost" title="Configure Folio Block">
            <SettingsIcon className="tiptap-button-icon" />
          </Button>
        )}
      </PopoverTrigger>

      <PopoverContent
        side="top"
        align="start"
        sideOffset={8}
        className="folio-tiptap-block-dialog-popover"
      >
        <FolioTiptapBlockDialogContent
          attributes={attributes}
          onSave={handleSave}
          onCancel={handleCancel}
        />
      </PopoverContent>
    </Popover>
  )
}