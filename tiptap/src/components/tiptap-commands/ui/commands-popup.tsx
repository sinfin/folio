import React from "react";
import { Command } from 'cmdk'

import "./commands-popup.scss"

export const COMMANDS_POPUP_OPEN_EVENT_NAME = "f-tiptap-commands:open"

const options = [
  { title: "Apple" },
  { title: "Banana" },
  { title: "Cherry" },
  { title: "Date" },
  { title: "Elderberry" },
  { title: "Fig" },
  { title: "Grape" },
  { title: "Honeydew" },
  { title: "Kiwi" },
  { title: "Lemon" },
  { title: "Mango" },
  { title: "Nectarine" },
  { title: "Orange" },
  { title: "Papaya" },
  { title: "Quince" },
  { title: "Raspberry" },
  { title: "Strawberry" },
  { title: "Tangerine" },
  { title: "Ugli fruit" },
  { title: "Vanilla bean" },
  { title: "Watermelon" }
]

export const CommandsPopup = ({
  editor: providedEditor,
}) => {
  const [value, setValue] = React.useState('apple')
  const [coords, setCoords] = React.useState(null)

  React.useEffect(() => {
    const handleEvent = (event: Event) => {
      setCoords(event.detail.coords)
    };

    window.addEventListener(COMMANDS_POPUP_OPEN_EVENT_NAME, handleEvent);

    return () => {
      window.removeEventListener(COMMANDS_POPUP_OPEN_EVENT_NAME, handleEvent);
    };
  }, [setCoords]);

  const opened = coords !== null

  if (!opened) {
    return
  }

  // const style = {
  //   top: `${coords.y}px`,
  //   left: `${coords.x}px`,
  // }

  const onSelect = (option) => {
    console.log("Selected option:", option);
    setCoords(null);
  }

  return (
    <div className="f-tipap-commands-popup">
      <div className="f-tipap-commands-popup__backdrop" onClick={() => { setCoords(null) }} />
      <div className="f-tipap-commands-popup__inner">
        <Command label="Command Menu" value={value} onValueChange={setValue}>
          <Command.Input autoFocus onKeyDown={(e) => e.key === 'Escape' ? setCoords(null) : null} />
          <Command.List>
            <Command.Empty>No results found.</Command.Empty>

            <Command.Group heading="Fruits">
              {options.map((option) => (
                <Command.Item key={option.title} value={option.title} onSelect={() => { onSelect(option) }}>
                  {option.title}
                </Command.Item>
              ))}
            </Command.Group>

            <Command.Item>Apple</Command.Item>
          </Command.List>
        </Command>
      </div>
    </div>
  )
}

export default CommandsPopup
