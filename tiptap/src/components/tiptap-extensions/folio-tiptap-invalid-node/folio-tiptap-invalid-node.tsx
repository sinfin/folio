import { Node, ReactNodeViewRenderer, NodeViewWrapper, type NodeViewProps } from "@tiptap/react";
import { InvalidNodeIndicator } from '@/components/tiptap-ui/invalid-node-indicator';
import translate from "@/lib/i18n";

const CLASS_NAME = "f-tiptap-invalid-node";

const TRANSLATIONS = {
  cs: {
    message: "Tento obsah nebude veřejně zobrazen. Můžete ho odstranit.",
  },
  en: {
    message: "This content will not be publicly displayed. You can remove it.",
  }
}

export const FolioTiptapInvalidNodeComponent: React.FC<NodeViewProps> = (props) => {
  const { node } = props;

  return (
    <NodeViewWrapper className={CLASS_NAME}>
      <InvalidNodeIndicator
        invalidNodeHash={node && node.attrs && node.attrs.invalidNodeHash}
        message={translate(TRANSLATIONS, "message")}
      />
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
        tag: `div.${CLASS_NAME}`,
        getAttrs: (element) => {
          if (typeof element === 'string') return false;
          return {
            invalidNodeHash: (() => {
              try {
                return JSON.parse(element.getAttribute("data-node-string") || "{}");
              } catch (error) {
                console.error("Error parsing invalidNodeHash:", error);
                return {};
              }
            })(),
          };
        },
      },
    ]
  },
});
