import * as React from "react"
import type { NodeViewProps } from "@tiptap/react"
import { NodeViewWrapper } from "@tiptap/react"
// import "@/components/tiptap-node/image-upload-node/image-upload-node.scss"

export const FolioTiptapNode: React.FC<NodeViewProps> = (props) => {
  const handleClick = React.useCallback(
    (e: React.MouseEvent<HTMLButtonElement>) => {
      if (!e.defaultPrevented) {
        console.log(props.node)
        window.top!.postMessage(
          {
            type: "f-tiptap-node:click",
            attrs: props.node.attrs,
          },
          "*",
        );
      }
    },
    [],
  );

  return (
    <NodeViewWrapper
      className="tiptap-folio-tiptap-node"
      tabIndex={0}
      onClick={handleClick}
    >
      {`folio-tiptap-node ${JSON.stringify(props.node)}`}
    </NodeViewWrapper>
  )
}
