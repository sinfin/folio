import { mergeAttributes, Node } from "@tiptap/react"
import { ReactNodeViewRenderer } from "@tiptap/react"
import { FolioTiptapBlock as FolioTiptapBlockComponent } from "./folio-tiptap-block"

export interface FolioTiptapBlockAttributes {
  title?: string
  content?: string
  blockType?: string
  apiUrl?: string
}

export interface FolioTiptapBlockOptions {
  /**
   * Base API URL for loading block content
   * @default '/api/folio-blocks'
   */
  apiUrl?: string
  /**
   * Callback for API errors
   */
  onError?: (error: Error) => void
  /**
   * Callback for successful API calls
   */
  onSuccess?: (html: string) => void
}

declare module "@tiptap/react" {
  interface Commands<ReturnType> {
    folioTiptapBlock: {
      setFolioTiptapBlock: (attributes?: FolioTiptapBlockAttributes) => ReturnType
    }
  }
}

/**
 * A TipTap node extension that creates a FolioTiptapBlock component.
 * The block shows a placeholder initially and opens a dialog to configure attributes.
 * It loads HTML content from an API based on the configured attributes.
 */
export const FolioTiptapBlock = Node.create<FolioTiptapBlockOptions>({
  name: "folioTiptapBlock",

  group: "block",

  draggable: true,

  selectable: true,

  atom: true,

  addOptions() {
    console.log('FolioTiptapBlock extension loading...')
    return {
      apiUrl: '/api/folio-blocks',
      onError: undefined,
      onSuccess: undefined,
    }
  },

  addAttributes() {
    return {
      title: {
        default: '',
        parseHTML: element => element.getAttribute('data-title'),
        renderHTML: attributes => {
          if (!attributes.title) {
            return {}
          }
          return {
            'data-title': attributes.title,
          }
        },
      },
      content: {
        default: '',
        parseHTML: element => element.getAttribute('data-content'),
        renderHTML: attributes => {
          if (!attributes.content) {
            return {}
          }
          return {
            'data-content': attributes.content,
          }
        },
      },
      blockType: {
        default: '',
        parseHTML: element => element.getAttribute('data-block-type'),
        renderHTML: attributes => {
          if (!attributes.blockType) {
            return {}
          }
          return {
            'data-block-type': attributes.blockType,
          }
        },
      },
      apiUrl: {
        default: this.options.apiUrl,
        parseHTML: element => element.getAttribute('data-api-url'),
        renderHTML: attributes => {
          if (!attributes.apiUrl) {
            return {}
          }
          return {
            'data-api-url': attributes.apiUrl,
          }
        },
      },
      htmlContent: {
        default: '',
        parseHTML: element => element.innerHTML,
        renderHTML: attributes => {
          return {}
        },
      },
    }
  },

  parseHTML() {
    return [{ tag: 'div[data-type="folio-tiptap-block"]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes(
        { 
          "data-type": "folio-tiptap-block",
          "class": "folio-tiptap-block-wrapper"
        }, 
        HTMLAttributes
      ),
      0
    ]
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapBlockComponent)
  },

  addCommands() {
    console.log('FolioTiptapBlock commands registered')
    return {
      setFolioTiptapBlock:
        (attributes = {}) =>
        ({ commands }) => {
          console.log('setFolioTiptapBlock command called with attributes:', attributes)
          const result = commands.insertContent({
            type: this.name,
            attrs: {
              ...attributes,
              apiUrl: attributes.apiUrl || this.options.apiUrl,
            },
          })
          console.log('insertContent result:', result)
          return result
        },
    }
  },

  /**
   * Adds Enter key handler to open the dialog when the block is selected.
   */
  addKeyboardShortcuts() {
    return {
      Enter: ({ editor }) => {
        const { selection } = editor.state
        const { nodeAfter } = selection.$from

        if (
          nodeAfter &&
          nodeAfter.type.name === "folioTiptapBlock" &&
          editor.isActive("folioTiptapBlock")
        ) {
          const nodeEl = editor.view.nodeDOM(selection.$from.pos)
          if (nodeEl && nodeEl instanceof HTMLElement) {
            // Trigger click to open dialog
            const firstChild = nodeEl.firstChild
            if (firstChild && firstChild instanceof HTMLElement) {
              firstChild.click()
              return true
            }
          }
        }
        return false
      },
    }
  },
})

export default FolioTiptapBlock