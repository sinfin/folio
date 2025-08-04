import * as React from "react";
import { isNodeSelection, type Editor } from "@tiptap/react";
import { Settings } from "lucide-react";

import translate from "@/lib/i18n";

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor";

// --- Icons ---
import { CornerDownLeftIcon } from "@/components/tiptap-icons/corner-down-left-icon";
import { ExternalLinkIcon } from "@/components/tiptap-icons/external-link-icon";
import { LinkIcon } from "@/components/tiptap-icons/link-icon";
import { TrashIcon } from "@/components/tiptap-icons/trash-icon";

// --- Lib ---
import { isMarkInSchema, sanitizeUrl } from "@/lib/tiptap-utils";

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button";
import { Button } from "@/components/tiptap-ui-primitive/button";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/tiptap-ui-primitive/popover";
import { Separator } from "@/components/tiptap-ui-primitive/separator";

// --- Styles ---
import "@/components/tiptap-ui/link-popover/link-popover.scss";

import type { FolioEditorToolbarButtonState } from "@/components/tiptap-editors/folio-editor/folio-editor-toolbar";

const TRANSLATIONS = {
  cs: {
    apply: "Uložit",
    openTheLink: "Otevřít odkaz",
    openSettings: "Upravit odkaz",
    removeLink: "Odstranit odkaz",
    placeholder: "Vložit URL odkazu …",
    settings: "Nastavit odkaz",
    openInNew: "Otevřít v novém okně",
  },
  en: {
    apply: "Apply",
    openTheLink: "Open the link",
    openSettings: "Edit link",
    removeLink: "Remove link",
    placeholder: "Paste link URL …",
    settings: "Link settings",
    openInNew: "Open in new window",
  },
};

export interface LinkHandlerProps {
  editor: Editor;
  onSetLink?: () => void;
  onLinkActive?: () => void;
  editorState: FolioEditorToolbarButtonState;
}

export interface LinkData {
  href: string | null;
  rel: string | null;
  target: string | null;
  // recordId: number | null
  // recordType: string | null
}

export interface LinkMainProps {
  linkData: LinkData;
  setLinkData: React.Dispatch<React.SetStateAction<LinkData>>;
  setLink: (optionalNewData?: LinkData) => void;
  removeLink: () => void;
  active: boolean;
}

const DEFAULT_STATE: LinkData = {
  href: null,
  rel: null,
  target: null,
  // recordId: null,
  // recordType: null,
};

export const useLinkHandler = (props: LinkHandlerProps) => {
  const { editor, onSetLink, onLinkActive, editorState } = props;
  const [linkData, setLinkData] = React.useState<LinkData>({
    ...DEFAULT_STATE,
  });

  React.useEffect(() => {
    if (!editorState.active) return;

    // Get URL immediately on mount
    const linkAttributes = editor.getAttributes("link");

    if (editor.isActive("link") && linkData.href === null) {
      setLinkData({
        href: linkAttributes.href || null,
        rel: linkAttributes.rel || null,
        target: linkAttributes.target || null,
        // recordId: linkAttributes.recordId || null,
        // recordType: linkAttributes.recordType || null,
      });
      onLinkActive?.();
    }
  }, [editorState.active, onLinkActive, linkData]);

  React.useEffect(() => {
    if (!editorState.active) return;

    const updateLinkState = () => {
      const linkAttributes = editor.getAttributes("link");

      setLinkData({
        href: linkAttributes.href || null,
        rel: linkAttributes.rel || null,
        target: linkAttributes.target || null,
        // recordId: linkAttributes.recordId || null,
        // recordType: linkAttributes.recordType || null,
      });

      if (editor.isActive("link") && linkAttributes.href !== null) {
        onLinkActive?.();
      }
    };

    editor.on("selectionUpdate", updateLinkState);
    return () => {
      editor.off("selectionUpdate", updateLinkState);
    };
  }, [editorState.active, onLinkActive, linkData]);

  const setLink = React.useCallback(
    (optionalNewData: LinkData = DEFAULT_STATE) => {
      if (!linkData.href && !optionalNewData.href) return;

      editor
        .chain()
        .focus()
        .extendMarkRange("link")
        .setLink({
          href: optionalNewData.href || linkData.href || "",
          rel: (typeof optionalNewData.rel === "undefined") ? linkData.rel : optionalNewData.rel,
          target: (typeof optionalNewData.target === "undefined") ? linkData.target : optionalNewData.target,
        })
        .run();

      setLinkData({ ...DEFAULT_STATE });

      onSetLink?.();
    },
    [editor, onSetLink, linkData.href],
  );

  const removeLink = React.useCallback(() => {
    if (!editor) return;

    editor
      .chain()
      .focus()
      .extendMarkRange("link")
      .unsetLink()
      .setMeta("preventAutolink", true)
      .run();

    setLinkData({ ...DEFAULT_STATE });
  }, [editor]);

  return {
    linkData,
    setLinkData,
    setLink,
    removeLink,
  };
};

export const LinkButton = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <Button
        type="button"
        className={className}
        data-style="ghost"
        role="button"
        tabIndex={-1}
        aria-label="Link"
        tooltip="Link"
        ref={ref}
        {...props}
      >
        {children || <LinkIcon className="tiptap-button-icon" />}
      </Button>
    );
  },
);

const LinkMain: React.FC<LinkMainProps> = ({
  linkData,
  setLinkData,
  setLink,
  removeLink,
  active,
}) => {
  const handleKeyDown = (event: React.KeyboardEvent) => {
    if (event.key === "Enter") {
      event.preventDefault();
      setLink();
    }
  };

  const handleSettingsLink = () => {
    window.top!.postMessage(
      {
        type: "f-tiptap-editor:open-link-popover",
        urlJson: linkData,
      },
      "*",
    );
  };

  const handleOpenLink = () => {
    if (!linkData.href) return;

    const safeUrl = sanitizeUrl(linkData.href, window.location.href);

    if (safeUrl !== "#") {
      window.open(safeUrl, "_blank", "noopener,noreferrer");
    }
  };

  return (
    <div className="f-tiptap-link-popover">
      <div className="tiptap-popover__rows">
        <div className="tiptap-popover__row">
          <input
            type="url"
            placeholder={translate(TRANSLATIONS, "placeholder")}
            value={linkData.href || ""}
            onChange={(e) =>
              setLinkData({ ...linkData, href: e.target.value || null })
            }
            onKeyDown={handleKeyDown}
            autoComplete="off"
            autoCorrect="off"
            autoCapitalize="off"
            className="f-tiptap-link-popover__input"
          />

          <div className="tiptap-button-group" data-orientation="horizontal">
            <Button
              type="button"
              onClick={() => setLink()}
              title={translate(TRANSLATIONS, "apply")}
              disabled={!linkData.href && !active}
              data-style="ghost"
            >
              <CornerDownLeftIcon className="tiptap-button-icon" />
            </Button>
          </div>

          <Separator />

          <div className="tiptap-button-group" data-orientation="horizontal">
            <Button
              type="button"
              onClick={handleOpenLink}
              title={translate(TRANSLATIONS, "openTheLink")}
              disabled={!linkData.href && !active}
              data-style="ghost"
            >
              <ExternalLinkIcon className="tiptap-button-icon" />
            </Button>

            <Button
              type="button"
              onClick={removeLink}
              title={translate(TRANSLATIONS, "removeLink")}
              disabled={!linkData.href && !active}
              data-style="ghost"
            >
              <TrashIcon className="tiptap-button-icon" />
            </Button>
          </div>
        </div>

        <div className="tiptap-popover__row">
          <Button
            type="button"
            onClick={handleSettingsLink}
            data-active-state={linkData.rel ? "on" : "off"}
            title={translate(TRANSLATIONS, "openSettings")}
            data-style="ghost"
            className="f-tiptap-link-popover__settings-button"
          >
            <Settings className="tiptap-button-icon" />
            {translate(TRANSLATIONS, "settings")}
          </Button>

          <label className="f-tiptap-link-popover__checkbox-label">
            <input
              type="checkbox"
              className="f-tiptap-link-popover__checkbox"
              checked={linkData.target === "_blank"}
              onChange={(e) => {
                setLink({
                  ...linkData,
                  target: e.target.checked ? "_blank" : null,
                })
              }}
            />
            <span className="f-tiptap-link-popover__checkbox-text">
              {translate(TRANSLATIONS, "openInNew")}
            </span>
          </label>
        </div>
      </div>
    </div>
  );
};

export interface LinkPopoverProps extends Omit<ButtonProps, "type"> {
  editor: Editor;
  editorState: FolioEditorToolbarButtonState;
}

export function LinkPopover({ editor, editorState }: LinkPopoverProps) {
  const [isOpen, setIsOpen] = React.useState(false);

  const onSetLink = () => {
    setIsOpen(false);
  };

  const onLinkActive = () => setIsOpen(true);

  const linkHandler = useLinkHandler({
    editor,
    onSetLink,
    onLinkActive,
    editorState,
  });

  const handleOnOpenChange = React.useCallback((nextIsOpen: boolean) => {
    setIsOpen(nextIsOpen);
  }, []);

  React.useEffect(() => {
    if (!isOpen) return;

    const handleMessage = (event: MessageEvent) => {
      if (
        process.env.NODE_ENV === "production" &&
        event.origin !== window.origin
      )
        return;

      if (event.data?.type === "f-input-tiptap:save-url-json") {
        // Example: update link data with the received urlJson
        if (event.data.urlJson) {
          const newData = {
            href: event.data.urlJson.href || null,
            rel: event.data.urlJson.rel || null,
            target: event.data.urlJson.target || null,
            // recordId: event.data.urlJson.recordId || null,
            // recordType: event.data.urlJson.recordType || null,
          };
          linkHandler.setLinkData(newData);
          linkHandler.setLink(newData);
        }
      }
    };

    window.addEventListener("message", handleMessage);
    return () => {
      window.removeEventListener("message", handleMessage);
    };
  }, [isOpen, linkHandler]);

  return (
    <Popover open={isOpen} onOpenChange={handleOnOpenChange}>
      <PopoverTrigger asChild>
        <LinkButton
          disabled={!editorState.enabled}
          data-active-state={editorState.active ? "on" : "off"}
          data-disabled={!editorState.enabled}
        />
      </PopoverTrigger>

      <PopoverContent>
        <LinkMain active={editorState.active} {...linkHandler} />
      </PopoverContent>
    </Popover>
  );
}

LinkButton.displayName = "LinkButton";
