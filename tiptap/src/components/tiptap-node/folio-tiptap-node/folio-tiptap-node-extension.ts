import { mergeAttributes, Node } from "@tiptap/react"
import { ReactNodeViewRenderer } from "@tiptap/react"
import { FolioTiptapNode } from "@/components/tiptap-node/folio-tiptap-node/folio-tiptap-node"

export interface FolioTiptapNodeOptions {
  /**
   * Acceptable file types for upload.
   * @default 'image/*'
   */
  accept?: string
  /**
   * Maximum number of files that can be uploaded.
   * @default 1
   */
  limit?: number
  /**
   * Maximum file size in bytes (0 for unlimited).
   * @default 0
   */
  maxSize?: number
  /**
   * Function to handle the upload process.
   */
  upload?: UploadFunction
  /**
   * Callback for upload errors.
   */
  onError?: (error: Error) => void
  /**
   * Callback for successful uploads.
   */
  onSuccess?: (url: string) => void
}

/**
 * A TipTap node extension that creates a component wrapping API HTML content.
 */
export const FolioTiptapNodeExtension = Node.create<FolioTiptapNodeOptions>({
  name: "folioTiptapNode",

  group: "block",

  draggable: true,

  selectable: true,

  atom: true,

  addAttributes() {
    return {
      version: {
        default: 1,
      },
      type: {
        default: "",
      },
      data: {
        default: {},
      },
    }
  },

  parseHTML() {
    // return [{ tag: 'div[data-type="image-upload"]' }]
    return null
  },

  renderHTML({ HTMLAttributes }) {
    return [
      "div",
      mergeAttributes({ "data-type": "folio-tiptap-node" }, HTMLAttributes),
    ]
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapNode)
  },

  addCommands() {
    return {
      setFolioTiptapNode:
        (node = {}) =>
        ({ commands }) => {
          console.log('inserting node', node)
          return commands.insertContent(node)
        },
    }
  },
})

export default FolioTiptapNodeExtension
