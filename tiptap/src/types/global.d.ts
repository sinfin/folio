// Global type declarations for the TipTap editor

declare module "*.json" {
  const value: unknown;
  export default value;
}

declare module "*.scss" {
  const content: { [className: string]: string };
  export default content;
}

declare module "*.css" {
  const content: { [className: string]: string };
  export default content;
}

declare module "tiptap-extension-global-drag-handle" {
  import { Extension } from "@tiptap/core";

  interface GlobalDragHandleOptions {
    dragHandleWidth?: number;
    scrollTreshold?: number;
  }

  const GlobalDragHandle: Extension<GlobalDragHandleOptions>;
  export default GlobalDragHandle;
}

declare module "tiptap-extension-auto-joiner" {
  import { Extension } from "@tiptap/core";

  interface AutoJoinerOptions {
    elementsToJoin?: string[];
  }

  const AutoJoiner: Extension<AutoJoinerOptions>;
  export default AutoJoiner;
}

// React 19 compatibility
declare module "react" {
  interface HTMLAttributes<T> extends AriaAttributes, DOMAttributes<T> {
    // React 19 specific attributes
    inert?: boolean;
  }
}

// Global interface augmentations
declare global {
  interface TiptapEditor {
    getJSON: () => Record<string, unknown>;
    view: {
      dom: HTMLElement;
    };
  }

  interface FolioTiptapNodeFromInput {
    title: { cs: string; en: string };
    type: string;
    config: {
      use_as_single_image_in_toolbar?: boolean;
      autoclick_cover?: boolean;
    };
  }

  interface StyledParagraphVariantFromInput {
    variant: string;
    title: { cs: string; en: string };
    icon?: string;
    tag?: string;
    class_name?: string;
  }

  type StyledWrapVariantFromInput = StyledParagraphVariantFromInput;

  interface FolioTiptapConfig {
    nodes?: FolioTiptapNodeFromInput[];
    styled_paragraph_variants?: StyledParagraphVariantFromInput[];
    styled_wrap_variants?: StyledWrapVariantFromInput[];
    enable_pages?: boolean;
    heading_levels?: import("@tiptap/extension-heading").Level[];
    autosave?: boolean;
    embed_node_class_name?: string;
  }

  interface FolioTiptapAutosaveIndicatorInfo {
    newRecord: boolean;
    hasUnsavedChanges: boolean;
    latestRevisionAt: string | null;
  }

  // Import CommandChain type for the interface below
  type CommandChain = import("@tiptap/core").CommandChain;

  // Common command parameters type for TipTap extensions
  type CommandParams = {
    dispatch:
      | ((tr: import("@tiptap/pm/state").Transaction) => void)
      | undefined;
    state: import("@tiptap/pm/state").EditorState;
  };

  interface FolioEditorCommandChain extends CommandChain {
    insertContent: (
      content: import("@tiptap/react").JSONContent | string,
    ) => FolioEditorCommandChain;
  }

  interface FolioEditor extends TiptapEditor {
    onCreate?: (content: { editor: TiptapEditor }) => void;
    onUpdate?: (content: { editor: TiptapEditor }) => void;
    defaultContent?: import("@tiptap/react").JSONContent;
    type: "rich-text" | "block";
    folioTiptapConfig: FolioTiptapConfig;
  }

  interface FolioEditorCommand {
    title: { cs: string; en: string };
    icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
    key: string;
    keymap?: string;
    dontShowAsActiveInCollapsedToolbar?: boolean;
    hideInToolbarDropdown?: boolean;
    command: (props: { chain: import("@tiptap/core").CommandChain }) => void;
  }

  interface FolioEditorCommandGroup {
    title: { cs: string; en: string };
    icon: React.ComponentType<React.SVGProps<SVGSVGElement>>;
    key: string;
    commands: FolioEditorCommand[];
  }

  interface FolioEditorCommandForSuggestion extends FolioEditorCommand {
    title: string;
    normalizedTitle: string;
  }

  interface FolioEditorCommandGroupForSuggestion
    extends FolioEditorCommandGroup {
    title: string;
    key: string;
    commandsForSuggestion: FolioEditorCommandForSuggestion[];
  }

  interface Window {
    __DEV__?: boolean;
    top: Window;
    Folio: {
      Tiptap: {
        root: ReturnType<typeof import("react-dom/client").createRoot> | null;
        init: (props: {
          node: HTMLElement;
          folioTiptapConfig?: FolioTiptapConfig;
          type: "rich-text" | "block";
          onCreate?: (content: { editor: TiptapEditor }) => void;
          onUpdate?: (content: { editor: TiptapEditor }) => void;
          content?: import("@tiptap/react").JSONContent;
          readonly: boolean;
          scrollTop?: number;
          autosaveIndicatorInfo?: FolioTiptapAutosaveIndicatorInfo;
        }) => ReturnType<typeof import("react-dom/client").createRoot>;
        destroy: () => void;
        getHeight: () => number;
      };
    };
  }

  // Promise support for older environments
  interface PromiseConstructor {
    new <T>(
      executor: (
        resolve: (value?: T | PromiseLike<T>) => void,
        reject: (reason?: unknown) => void,
      ) => void,
    ): Promise<T>;
  }
}

// TipTap command type augmentations
declare module "@tiptap/react" {
  interface Commands<ReturnType> {
    folioTiptapNode: {
      setFolioTiptapNode: (
        node?: import("@tiptap/react").JSONContent,
        uniqueId: number | null = null,
      ) => ReturnType;
    };
  }
}

export {};
