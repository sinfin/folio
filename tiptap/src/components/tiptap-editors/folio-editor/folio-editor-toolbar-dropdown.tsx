import React from "react";
import type { Editor } from '@tiptap/react';
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuGroup,
} from "@/components/tiptap-ui-primitive/dropdown-menu"
import translate from "@/lib/i18n";
import { ChevronDownIcon } from "@/components/tiptap-icons/chevron-down-icon"
import { Button } from "@/components/tiptap-ui-primitive/button"

import type { FolioEditorToolbarButtonState } from './folio-editor-toolbar';

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
  onClick: () => void;
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
  editorState: FolioEditorToolbarButtonState;
  commandGroup: FolioEditorCommandGroup;
}

const makeOnClick = ({ command, editor }: { command: FolioEditorCommand; editor: Editor }) => () => {
  const chain = editor.chain()
  chain.focus()
  command.command({ chain })
  chain.run()
}

export function FolioEditorToolbarDropdown({
  editorState,
  commandGroup,
  editor,
}: FolioEditorToolbarDropdownProps) {
  if (!editor) return

  const [isOpen, setIsOpen] = React.useState(false)

  const handleOnOpenChange = React.useCallback(
    (open: boolean) => {
      setIsOpen(open)
    },
    []
  )

  const getActiveItem = React.useCallback(() => {
    if (editorState.value) {
      return commandGroup.commands.find((command) => !command.dontShowAsActiveInCollapsedToolbar && command.key === editorState.value) || null
    } else {
      return null
    }
  }, [editorState.value, commandGroup.commands])

  const activeItem = getActiveItem()
  const ActiveIcon = activeItem ? activeItem.icon : commandGroup.icon;
  const tooltip = commandGroup.title[document.documentElement.lang as keyof typeof commandGroup.title] || commandGroup.title.en;

  return (
    <DropdownMenu open={isOpen} onOpenChange={handleOnOpenChange}>
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
          {commandGroup.commands.map((command) => (
            <DropdownMenuItem key={command.key} asChild>
              <FolioEditorToolbarDropdownButton
                active={editorState.value ? (command.key === editorState.value) : false}
                enabled={editorState.enabled}
                onClick={makeOnClick({ editor, command })}
              >
                <command.icon className="tiptap-button-icon" />
                {command.title[document.documentElement.lang as keyof typeof command.title] || command.title.en}
              </FolioEditorToolbarDropdownButton>
            </DropdownMenuItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
