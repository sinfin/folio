import * as React from "react"
import { isNodeSelection, type Editor } from "@tiptap/react"

// --- Hooks ---
import { useTiptapEditor } from "@/hooks/use-tiptap-editor"

// --- Icons ---
import { ChevronDownIcon } from "@/components/tiptap-icons/chevron-down-icon"
import { HeadingIcon } from "@/components/tiptap-icons/heading-icon"

// --- Lib ---
import { isNodeInSchema } from "@/lib/tiptap-utils"

// --- Tiptap UI ---
import {
  HeadingButton,
  headingIcons,
  type Level,
  getFormattedHeadingName,
} from "@/components/tiptap-ui/heading-button/heading-button"

// --- UI Primitives ---
import type { ButtonProps } from "@/components/tiptap-ui-primitive/button"
import { Button } from "@/components/tiptap-ui-primitive/button"
import {
  DropdownMenu,
  DropdownMenuTrigger,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuGroup,
} from "@/components/tiptap-ui-primitive/dropdown-menu"

export interface HeadingDropdownMenuProps extends Omit<ButtonProps, "type"> {
  editor?: Editor | null
  levels?: Level[]
  value?: string
  active: boolean
  enabled: boolean
}

export function HeadingDropdownMenu({
  editor,
  levels = [2, 3, 4],
  value,
  active,
  enabled,
  ...props
}: HeadingDropdownMenuProps) {
  if (!editor) return null

  const [isOpen, setIsOpen] = React.useState(false)

  const handleOnOpenChange = React.useCallback(
    (open: boolean) => {
      setIsOpen(open)
    },
    []
  )

  const getActiveIcon = React.useCallback(() => {
    let activeLevel: Level | undefined = undefined

    if (active) {
      switch (value) {
        case "h2":
          activeLevel = 2
          break
        case "h3":
          activeLevel = 3
          break
        case "h4":
          activeLevel = 4
          break
        default:
          undefined
      }
    }

    if (!activeLevel) return <HeadingIcon className="tiptap-button-icon" />

    const ActiveIcon = headingIcons[activeLevel]
    return <ActiveIcon className="tiptap-button-icon" />
  }, [active, value])

  return (
    <DropdownMenu open={isOpen} onOpenChange={handleOnOpenChange}>
      <DropdownMenuTrigger asChild>
        <Button
          type="button"
          disabled={!enabled}
          data-style="ghost"
          data-active-state={active ? "on" : "off"}
          data-disabled={!enabled}
          role="button"
          tabIndex={-1}
          aria-label="Format text as heading"
          aria-pressed={active}
          tooltip="Heading"
          {...props}
        >
          {getActiveIcon()}
          <ChevronDownIcon className="tiptap-button-dropdown-small" />
        </Button>
      </DropdownMenuTrigger>

      <DropdownMenuContent>
        <DropdownMenuGroup>
          {levels.map((level) => (
            <DropdownMenuItem key={`heading-${level}`} asChild>
              <HeadingButton
                editor={editor}
                level={level}
                text={getFormattedHeadingName(level)}
                tooltip={""}
              />
            </DropdownMenuItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

export default HeadingDropdownMenu
