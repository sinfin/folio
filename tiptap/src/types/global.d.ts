// Global type declarations for the TipTap editor

declare module "*.json" {
  const value: any;
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
  interface FolioEditor {
    onCreate?: (content: { editor: TiptapEditor }) => void;
    onUpdate?: (content: { editor: TiptapEditor }) => void;
    defaultContent?: any;
    type: "rich-text" | "block";
  }

  interface TiptapEditor {
    getJSON: () => Record<string, unknown>;
    view: {
      dom: HTMLElement;
    };
  }

  interface Window {
    __DEV__?: boolean;
    top: Window;
    Folio: {
      Tiptap: {
        root: HTMLElement | null;
        init: (props: {
          node: HTMLElement;
          type: "rich-text" | "block";
          onCreate?: (content: { editor: TiptapEditor }) => void;
          onUpdate?: (content: { editor: TiptapEditor }) => void;
          content?: any;
        }) => ReturnType<typeof import("react-dom/client").createRoot>;
        destroy: (
          root: ReturnType<typeof import("react-dom/client").createRoot>,
        ) => void;
      };
    };
  }

  // Promise support for older environments
  interface PromiseConstructor {
    new <T>(
      executor: (
        resolve: (value?: T | PromiseLike<T>) => void,
        reject: (reason?: any) => void,
      ) => void,
    ): Promise<T>;
  }
}

// TipTap command type augmentations
declare module "@tiptap/react" {
  interface Commands<ReturnType> {
    folioTiptapBlock: {
      setFolioTiptapBlock: (attributes?: {
        title?: string;
        content?: string;
        blockType?: string;
        apiUrl?: string;
      }) => ReturnType;
    };
  }
}

export {};
