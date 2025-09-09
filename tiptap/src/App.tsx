import { FolioEditor } from "@/components/tiptap-editors/folio-editor";
import type { JSONContent } from "@tiptap/react";

import "./App.css";

interface AppProps {
  onUpdate?: (content: { editor: TiptapEditor }) => void;
  onCreate?: (content: { editor: TiptapEditor }) => void;
  defaultContent?: JSONContent;
  type?: "rich-text" | "block";
  folioTiptapConfig: FolioTiptapConfig;
  readonly: boolean;
  initialScrollTop: number | null;
  autosaveIndicatorInfo?: FolioTiptapAutosaveIndicatorInfo;
}

function App({
  onCreate,
  onUpdate,
  defaultContent,
  type,
  folioTiptapConfig,
  readonly,
  initialScrollTop,
  autosaveIndicatorInfo,
}: AppProps) {
  switch (type) {
    case "block":
    case "rich-text":
      return (
        <FolioEditor
          onCreate={onCreate}
          onUpdate={onUpdate}
          defaultContent={defaultContent}
          type={type as "block" | "rich-text"}
          folioTiptapConfig={folioTiptapConfig}
          readonly={readonly}
          initialScrollTop={initialScrollTop}
          autosaveIndicatorInfo={autosaveIndicatorInfo}
        />
      );
    default:
      throw new Error(`Unknown editor type: ${type}`);
  }
}

export default App;
