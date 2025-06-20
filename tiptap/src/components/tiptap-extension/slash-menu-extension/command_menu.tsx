import * as React from "react";
import { Command } from 'cmdk'
import { Popover, PopoverContent } from "@/components/tiptap-ui-primitive/popover"

class CommandMenu extends React.Component {
  render () {
    return (
      <Popover open={true}>
        <PopoverContent aria-label="Select command">
          <Command>
            <Command.Input />
            <Command.List>
              <Command.Empty>No results found.</Command.Empty>

              <Command.Group heading="Letters">
                {this.props.items.map((item, index) => (
                  <Command.Item key={item.title} onSelect={() => item.command(this.props)}>
                    {item.title}
                  </Command.Item>
                ))}
              </Command.Group>
            </Command.List>
          </Command>
        </PopoverContent>
      </Popover>
    )
  }
}

export default CommandMenu
