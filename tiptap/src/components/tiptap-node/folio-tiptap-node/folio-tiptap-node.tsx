import * as React from "react"
import type { NodeViewProps } from "@tiptap/react"
import { NodeViewWrapper } from "@tiptap/react"
// import "@/components/tiptap-node/image-upload-node/image-upload-node.scss"

export const FolioTiptapNode: React.FC<NodeViewProps> = (props) => {
  return (
    <NodeViewWrapper
      className="tiptap-folio-tiptap-node"
      tabIndex={0}
    >
      {`folio-tiptap-node ${JSON.stringify(props.node)}`}
    </NodeViewWrapper>
  )
}
