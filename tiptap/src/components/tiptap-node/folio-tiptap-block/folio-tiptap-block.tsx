import * as React from "react"
import type { NodeViewProps } from "@tiptap/react"
import { NodeViewWrapper } from "@tiptap/react"
import type { FolioTiptapBlockAttributes } from "./folio-tiptap-block-extension"
import { FolioTiptapBlockDialog } from "./folio-tiptap-block-dialog"

// --- UI Primitives ---
import { Button } from "@/components/tiptap-ui-primitive/button"

// --- Icons ---
import { SettingsIcon } from "@/components/tiptap-icons/settings-icon"
import { BlocksIcon } from "@/components/tiptap-icons/blocks-icon"
import { LoaderIcon } from "@/components/tiptap-icons/loader-icon"
import { AlertCircleIcon } from "@/components/tiptap-icons/alert-circle-icon"

// --- Styles ---
import "./folio-tiptap-block.scss"

interface ApiResponse {
  html: string
  success: boolean
  error?: string
}

const mockApiCall = async (attributes: FolioTiptapBlockAttributes): Promise<ApiResponse> => {
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 1000))
  
  // Mock different responses based on block type
  const { title, content, blockType } = attributes
  
  if (!blockType) {
    throw new Error("Block type is required")
  }
  
  // Generate mock HTML based on block type
  let mockHtml = ''
  
  switch (blockType) {
    case 'hero':
      mockHtml = `
        <div class="folio-block folio-block-hero">
          <h1>${title || 'Hero Title'}</h1>
          <p>${content || 'This is a hero section with compelling content that draws visitors in.'}</p>
          <button class="btn btn-primary">Get Started</button>
        </div>
      `
      break
    case 'gallery':
      mockHtml = `
        <div class="folio-block folio-block-gallery">
          <h2>${title || 'Image Gallery'}</h2>
          <div class="gallery-grid">
            <div class="gallery-item">📷 Image 1</div>
            <div class="gallery-item">📷 Image 2</div>
            <div class="gallery-item">📷 Image 3</div>
            <div class="gallery-item">📷 Image 4</div>
          </div>
          ${content ? `<p>${content}</p>` : ''}
        </div>
      `
      break
    case 'testimonial':
      mockHtml = `
        <div class="folio-block folio-block-testimonial">
          <h3>${title || 'Customer Testimonial'}</h3>
          <blockquote>
            "${content || 'This product has completely transformed our workflow. Highly recommended!'}"
          </blockquote>
          <cite>— Happy Customer</cite>
        </div>
      `
      break
    case 'cta':
      mockHtml = `
        <div class="folio-block folio-block-cta">
          <h2>${title || 'Ready to Get Started?'}</h2>
          <p>${content || 'Join thousands of satisfied customers today.'}</p>
          <div class="cta-buttons">
            <button class="btn btn-primary">Start Free Trial</button>
            <button class="btn btn-secondary">Learn More</button>
          </div>
        </div>
      `
      break
    case 'feature':
      mockHtml = `
        <div class="folio-block folio-block-feature">
          <h3>${title || 'Amazing Feature'}</h3>
          <div class="feature-content">
            <div class="feature-icon">⭐</div>
            <div class="feature-text">
              <p>${content || 'This feature will help you accomplish your goals more efficiently than ever before.'}</p>
            </div>
          </div>
        </div>
      `
      break
    case 'custom':
      mockHtml = `
        <div class="folio-block folio-block-custom">
          <h3>${title || 'Custom Block'}</h3>
          <div class="custom-content">
            ${content || '<p>This is a custom block with your own content and styling.</p>'}
          </div>
        </div>
      `
      break
    default:
      mockHtml = `
        <div class="folio-block folio-block-default">
          <h3>${title || 'Folio Block'}</h3>
          <p>${content || 'This is a generic Folio block.'}</p>
        </div>
      `
  }
  
  return {
    html: mockHtml,
    success: true
  }
}

const useApiContent = (
  attributes: FolioTiptapBlockAttributes,
  shouldLoad: boolean
) => {
  const [loading, setLoading] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)
  const [htmlContent, setHtmlContent] = React.useState<string>('')

  const loadContent = React.useCallback(async () => {
    if (!shouldLoad || (!attributes.title && !attributes.blockType)) {
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await mockApiCall(attributes)
      
      if (response.success) {
        setHtmlContent(response.html)
      } else {
        throw new Error(response.error || 'Failed to load content')
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError(errorMessage)
      console.error('Failed to load Folio block content:', err)
    } finally {
      setLoading(false)
    }
  }, [attributes, shouldLoad])

  React.useEffect(() => {
    loadContent()
  }, [loadContent])

  return {
    loading,
    error,
    htmlContent,
    reload: loadContent
  }
}

const FolioTiptapBlockPlaceholder: React.FC<{
  onConfigure: () => void
  attributes: FolioTiptapBlockAttributes
}> = ({ onConfigure, attributes }) => (
  <div className="folio-tiptap-block-placeholder">
    <div className="folio-tiptap-block-placeholder-content">
      <div className="folio-tiptap-block-placeholder-icon">
        <BlocksIcon />
      </div>
      <h4 className="folio-tiptap-block-placeholder-title">
        {attributes.title || 'Folio Block'}
      </h4>
      <p className="folio-tiptap-block-placeholder-description">
        {attributes.blockType 
          ? `Block Type: ${attributes.blockType}`
          : 'Click to configure this Folio block'
        }
      </p>
      <Button
        onClick={onConfigure}
        data-style="primary"
        className="folio-tiptap-block-configure-btn"
      >
        <SettingsIcon className="tiptap-button-icon" />
        {attributes.title ? 'Edit Block' : 'Configure Block'}
      </Button>
    </div>
  </div>
)

const FolioTiptapBlockContent: React.FC<{
  htmlContent: string
  onEdit: () => void
  attributes: FolioTiptapBlockAttributes
}> = ({ htmlContent, onEdit, attributes }) => (
  <div className="folio-tiptap-block-content">
    <div className="folio-tiptap-block-header">
      <span className="folio-tiptap-block-title">
        {attributes.title || 'Folio Block'}
      </span>
      <Button
        onClick={onEdit}
        data-style="ghost"
        className="folio-tiptap-block-edit-btn"
        title="Edit block"
      >
        <SettingsIcon className="tiptap-button-icon" />
      </Button>
    </div>
    <div 
      className="folio-tiptap-block-rendered-content"
      dangerouslySetInnerHTML={{ __html: htmlContent }}
    />
  </div>
)

const FolioTiptapBlockLoading: React.FC = () => (
  <div className="folio-tiptap-block-loading">
    <LoaderIcon className="folio-tiptap-block-loading-icon" />
    <span className="folio-tiptap-block-loading-text">Loading block content...</span>
  </div>
)

const FolioTiptapBlockError: React.FC<{
  error: string
  onRetry: () => void
  onConfigure: () => void
}> = ({ error, onRetry, onConfigure }) => (
  <div className="folio-tiptap-block-error">
    <div className="folio-tiptap-block-error-content">
      <AlertCircleIcon className="folio-tiptap-block-error-icon" />
      <h4 className="folio-tiptap-block-error-title">Failed to load block</h4>
      <p className="folio-tiptap-block-error-message">{error}</p>
      <div className="folio-tiptap-block-error-actions">
        <Button onClick={onRetry} data-style="ghost">
          Retry
        </Button>
        <Button onClick={onConfigure} data-style="primary">
          <SettingsIcon className="tiptap-button-icon" />
          Configure
        </Button>
      </div>
    </div>
  </div>
)

export const FolioTiptapBlock: React.FC<NodeViewProps> = (props) => {
  const { node, updateAttributes } = props
  const attributes = node.attrs as FolioTiptapBlockAttributes
  
  const [isDialogOpen, setIsDialogOpen] = React.useState(false)
  
  // Determine if we should auto-open dialog for new blocks
  const isNewBlock = !attributes.title && !attributes.blockType
  
  React.useEffect(() => {
    if (isNewBlock) {
      setIsDialogOpen(true)
    }
  }, [isNewBlock])

  // Only load content if we have configuration
  const hasConfiguration = attributes.title || attributes.blockType
  const { loading, error, htmlContent, reload } = useApiContent(
    attributes, 
    !!hasConfiguration
  )

  const handleSave = (newAttributes: FolioTiptapBlockAttributes) => {
    updateAttributes(newAttributes)
    setIsDialogOpen(false)
  }

  const handleCancel = () => {
    // If it's a new block and user cancels, delete the node
    if (isNewBlock) {
      const pos = props.getPos()
      props.editor
        .chain()
        .focus()
        .deleteRange({ from: pos, to: pos + 1 })
        .run()
    }
    setIsDialogOpen(false)
  }

  const handleConfigure = () => {
    setIsDialogOpen(true)
  }

  const renderContent = () => {
    if (!hasConfiguration) {
      return (
        <FolioTiptapBlockPlaceholder
          onConfigure={handleConfigure}
          attributes={attributes}
        />
      )
    }

    if (loading) {
      return <FolioTiptapBlockLoading />
    }

    if (error) {
      return (
        <FolioTiptapBlockError
          error={error}
          onRetry={reload}
          onConfigure={handleConfigure}
        />
      )
    }

    if (htmlContent) {
      return (
        <FolioTiptapBlockContent
          htmlContent={htmlContent}
          onEdit={handleConfigure}
          attributes={attributes}
        />
      )
    }

    return (
      <FolioTiptapBlockPlaceholder
        onConfigure={handleConfigure}
        attributes={attributes}
      />
    )
  }

  return (
    <NodeViewWrapper className="folio-tiptap-block-wrapper">
      <FolioTiptapBlockDialog
        isOpen={isDialogOpen}
        onOpenChange={setIsDialogOpen}
        attributes={attributes}
        onSave={handleSave}
        onCancel={handleCancel}
      >
        <div className="folio-tiptap-block">
          {renderContent()}
        </div>
      </FolioTiptapBlockDialog>
    </NodeViewWrapper>
  )
}