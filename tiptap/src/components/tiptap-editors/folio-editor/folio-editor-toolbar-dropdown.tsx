import React from "react";
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuGroup,
} from "@/components/tiptap-ui-primitive/dropdown-menu"
import translate from "@/lib/i18n";
import { ChevronDownIcon } from "@/components/tiptap-icons/chevron-down-icon"
import { HeadingIcon } from "@/components/tiptap-icons/heading-icon"
import { Button } from "@/components/tiptap-ui-primitive/button"

const TRANSLATIONS = {
  cs: {
    tooltip: "Formát textu",
  },
  en: {
    tooltip: "Text format",
  }
}

export interface FolioEditorToolbarDropdownItemProps {
  title: string;
  icon?: React.ComponentType<React.SVGProps<SVGSVGElement>>;
  comman?: (params: {
    editor: Editor;
    range: Range;
  }) => void;
}

export interface FolioEditorToolbarDropdownButtonProps {
  children: React.ReactNode;
  enabled: boolean;
  active: boolean;
  tooltip?: string;
}

export function FolioEditorToolbarDropdownButton({
  children,
  enabled,
  active,
  onClick,
  tooltip,
}: FolioEditorToolbarDropdownButtonProps) {
  return (
    <Button
      type="button"
      disabled={!enabled}
      data-style="ghost"
      data-active-state={active ? "on" : "off"}
      data-disabled={!enabled}
      role="button"
      tabIndex={-1}
      aria-label={tooltip}
      aria-pressed={active}
      tooltip={tooltip}
      onClick={onClick}
    >
      {children}
    </Button>
  )
}

export interface FolioEditorToolbarDropdownProps {
  editor: Editor | null;
  commands: any[];
}

export function FolioEditorToolbarDropdown({
  editorState,
  commands,
  editor,
}: FolioEditorToolbarDropdownProps) {
  const [isOpen, setIsOpen] = React.useState(false)

  const handleOnOpenChange = React.useCallback(
    (open: boolean) => {
      setIsOpen(open)
    },
    []
  )

  const getActiveItem = React.useCallback(() => {
    if (editorState.value) {
      return commands.find((command) => !command.dontShowAsActiveInCollapsedToolbar && command.key === editorState.value) || null
    } else {
      return null
    }
  }, [editorState.value, commands])

  const activeItem = getActiveItem()
  const ActiveIcon = activeItem ? activeItem.icon : HeadingIcon;
  const tooltip = translate(TRANSLATIONS, "tooltip")

  return (
    <DropdownMenu open={isOpen} onOpenChange={handleOnOpenChange} className="f-tiptap-editor-toolbar-dropdown">
      <DropdownMenuTrigger asChild>
        <Button
          type="button"
          disabled={!editorState.enabled}
          data-style="ghost"
          data-active-state={editorState.active ? "on" : "off"}
          data-disabled={!editorState.enabled}
          role="button"
          tabIndex={-1}
          aria-label={tooltip}
          aria-pressed={editorState.active}
          tooltip={tooltip}
        >
          <ActiveIcon className="tiptap-button-icon" />
          <ChevronDownIcon className="tiptap-button-dropdown-small" />
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent>
        <DropdownMenuGroup>
          {commands.map((item) => (
            <DropdownMenuItem key={item.key} asChild>
              <FolioEditorToolbarDropdownButton
                active={editorState.value ? (item.key === editorState.value) : false}
                enabled={editorState.enabled}
                onClick={() => {
                  item.command({ editor, slash: false })
                }}
              >
                <item.icon className="tiptap-button-icon" />
                {item.title}
              </FolioEditorToolbarDropdownButton>
            </DropdownMenuItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
