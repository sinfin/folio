import * as React from "react"
import { isNodeSelection, type Editor } from "@tiptap/react"

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor"

// --- Icons ---
import { ChevronDownIcon } from "@/components/tiptap-icons/chevron-down-icon"
import { ListIcon } from "@/components/tiptap-icons/list-icon"
import { ListOrderedIcon } from "@/components/tiptap-icons/list-ordered-icon"

// --- Lib ---
import { isNodeInSchema } from "@/lib/tiptap-utils"

// --- Tiptap UI ---
import {
  ListButton,
  canToggleList,
  isListActive,
  listOptions,
  type ListType,
} from "@/components/tiptap-ui/list-button/list-button"

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button"
import { Button } from "@/components/tiptap-ui-primitive/button"
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
} from "@/components/tiptap-ui-primitive/dropdown-menu"

export interface ListDropdownMenuProps extends Omit<ButtonProps, "type"> {
  /**
   * The TipTap editor instance.
   */
  editor?: Editor
  /**
   * The list types to display in the dropdown.
   */
  types?: ListType[]
  active: boolean
  enabled: boolean
  value: string | undefined
}

export function canToggleAnyList(
  editor: Editor | null,
  listTypes: ListType[]
): boolean {
  if (!editor) return false
  return listTypes.some((type) => canToggleList(editor, type))
}

export function isAnyListActive(
  editor: Editor | null,
  listTypes: ListType[]
): boolean {
  if (!editor) return false
  return listTypes.some((type) => isListActive(editor, type))
}

export function getFilteredListOptions(
  availableTypes: ListType[]
): typeof listOptions {
  return listOptions.filter(
    (option) => !option.type || availableTypes.includes(option.type)
  )
}

export function shouldShowListDropdown(params: {
  editor: Editor | null
  listTypes: ListType[]
  listInSchema: boolean
  canToggleAny: boolean
}): boolean {
  const { editor, listInSchema, canToggleAny } = params

  if (!listInSchema || !editor) {
    return false
  }

  return true
}

export function ListDropdownMenu({
  editor: providedEditor,
  types = ["bulletList", "orderedList"],
  active,
  enabled,
  value,
  ...props
}: ListDropdownMenuProps) {
  const editor = useTiptapEditor(providedEditor)

  const [isOpen, setIsOpen] = React.useState(false)

  const getActiveIcon = React.useCallback(() => {
    if (value === "orderedList") {
      return <ListOrderedIcon className="tiptap-button-icon" />
    }

    return <ListIcon className="tiptap-button-icon" />
  }, [active, value])

  const handleOnOpenChange = React.useCallback(
    (open: boolean) => setIsOpen(open),
    []
  )

  const filteredLists = React.useMemo(
    () => getFilteredListOptions(types),
    [types]
  )

  return (
    <DropdownMenu open={isOpen} onOpenChange={handleOnOpenChange}>
      <DropdownMenuTrigger asChild>
        <Button
          type="button"
          data-style="ghost"
          data-active-state={active ? "on" : "off"}
          role="button"
          tabIndex={-1}
          aria-label="List options"
          tooltip="List"
          {...props}
        >
          {getActiveIcon()}
          <ChevronDownIcon className="tiptap-button-dropdown-small" />
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent>
        <DropdownMenuGroup>
          {filteredLists.map((option) => (
            <DropdownMenuItem key={option.type} asChild>
              <ListButton
                editor={editor}
                type={option.type}
                text={option.label}
                tooltip={""}
              />
            </DropdownMenuItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

export default ListDropdownMenu
