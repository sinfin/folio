import { Node, ReactNodeViewRenderer, NodeViewWrapper, type NodeViewProps } from "@tiptap/react";
import { AlertCircleIcon } from '@/components/tiptap-icons';
import translate from "@/lib/i18n";

import "./folio-tiptap-invalid-node.scss"

const CLASS_NAME = "f-tiptap-invalid-node";

const TRANSLATIONS = {
  cs: {
    title: "Nevalidní obsah",
    hint: "Tento obsah nebude veřejně zobrazen. Můžete ho odstranit.",
  },
  en: {
    title: "Invalid content",
    hint: "This content will not be publicly displayed. You can remove it.",
  }
}

const DEFAULT_INVALID_NODE_HASH = {
  type: "Unknown type"
}

const FolioTiptapInvalidNodeComponent: React.FC<NodeViewProps> = (props) => {
  const { node } = props;
  let invalidNodeHash = node && node.attrs && node.attrs.invalidNodeHash;
  invalidNodeHash = invalidNodeHash || DEFAULT_INVALID_NODE_HASH;

  return (
    <NodeViewWrapper className={CLASS_NAME}>
      <h4 className={`${CLASS_NAME}__title`}>
        <AlertCircleIcon />
        {translate(TRANSLATIONS, "title")}
      </h4>

      <p className={`${CLASS_NAME}__hint`}>
        {translate(TRANSLATIONS, "hint")}
      </p>

      <pre className={`${CLASS_NAME}__pre`}>
        <code>
          {JSON.stringify(invalidNodeHash, null, 2)}
        </code>
      </pre>
    </NodeViewWrapper>
  );
}

export const FolioTiptapInvalidNode = Node.create<Record<string, never>>({
  name: "folioTiptapInvalidNode",

  group: "block",

  draggable: true,

  selectable: true,

  atom: true,

  code: true,

  isolating: true,

  renderHTML({ HTMLAttributes }: { HTMLAttributes: Record<string, any> }) {
    return ["div", { ...HTMLAttributes, class: CLASS_NAME }, 0];
  },

  addAttributes() {
    return {
      invalidNodeHash: {
        default: {},
        parseHTML: (element: HTMLElement) =>
          JSON.parse(element.getAttribute("data-node-string") || "{}"),
        renderHTML: (attributes: { invalidNodeHash: string }) => ({
          "data-node-string": JSON.stringify(attributes.invalidNodeHash),
        }),
      },
    };
  },

  addNodeView() {
    return ReactNodeViewRenderer(FolioTiptapInvalidNodeComponent);
  },

  parseHTML() {
    return [
      {
        tag: `div[class="${CLASS_NAME}"]`,
      },
    ]
  },
});
