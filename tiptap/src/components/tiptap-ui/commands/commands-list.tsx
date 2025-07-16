import React from "react";
import translate from "@/lib/i18n";

import "./commands-list.scss"

const TRANSLATIONS = {
  cs: {
    defaultAction: 'Napsat /{query} do obsahu',
  },
  en: {
    defaultAction: 'Type /{query} to content',
  },
};

interface CommandGroup {
  title: string;
  items: CommandItem[];
}

interface CommandItem {
  title: string;
  command?: (params: any) => void;
  [key: string]: any;
}

interface CommandsListProps {
  items: CommandItem[];
  command: (item: CommandItem) => void;
}

interface CommandsListState {
  selectedIndex: number;
}

export class CommandsList extends React.Component<
  CommandsListProps,
  CommandsListState
> {
  constructor(props: CommandsListProps) {
    super(props);

    this.state = {
      selectedIndex: 0,
    };
  }

  onKeyDown({ event }: { event: KeyboardEvent }) {
    if (event.key === "ArrowUp") {
      this.upHandler();
      return true;
    }

    if (event.key === "ArrowDown" || event.key === "Tab") {
      this.downHandler();
      return true;
    }

    if (event.key === "Enter") {
      this.enterHandler();
      return true;
    }

    return false;
  }

  setSelectedIndex(selectedIndex: number) {
    this.setState({ selectedIndex });
  }

  upHandler() {
    let newIndex = this.state.selectedIndex - 1;

    if (newIndex < 0) {
      let itemsCount = 0
      this.props.items.forEach((group) => { itemsCount += group.items.length })

      newIndex = itemsCount - 1;
    }

    this.setSelectedIndex(newIndex)
  }

  downHandler() {
    let itemsCount = 0
    this.props.items.forEach((group) => { itemsCount += group.items.length })

    let newIndex = this.state.selectedIndex + 1;

    if (newIndex >= itemsCount) {
      newIndex = 0
    }

    this.setSelectedIndex(newIndex)
  }

  enterHandler() {
    let index = -1
    let targetItem = null

    this.props.items.forEach((group) => {
      if (targetItem) return

      group.items.forEach((item) => {
        if (targetItem) return
        index += 1

        if (index === this.state.selectedIndex) {
          targetItem = item;
        }
      })
    })

    this.selectItem(targetItem);
  }

  selectItem(item: CommandItem) {
    if (item) {
      this.props.command(item);
    }
  }

  componentDidUpdate(
    prevProps: CommandsListProps,
    _prevState: CommandsListState,
  ) {
    if (prevProps.items.length !== this.props.items.length) {
      this.setState({ selectedIndex: 0 });
    }
  }

  render() {
    let index = -1

    return (
      <div className="f-tiptap-commands-list">
        {this.props.items.length > 0 ? (
          <div className="f-tiptap-commands-list__section">
            {this.props.items.map((group: CommandGroup) => (
              <>
                <div className="f-tiptap-commands-list__section-heading">
                  {group.title}
                </div>

                <ul className="f-tiptap-commands-list__section-ul">
                  {group.items.map((item: CommandItem) => {
                    index += 1

                    return (
                      <li className="f-tiptap-commands-list__section-li" key={`${group.title}-${item.title}`}>
                        <button
                          type="button"
                          className="f-tiptap-commands-list__item f-tiptap-commands-list__item--active"
                          data-selected={String(index === this.state.selectedIndex)}
                          onClick={() => this.selectItem(item)}
                          onMouseOver={() => this.setSelectedIndex(index)}
                        >
                          <span className="f-tiptap-commands-list__item-inner">
                            <span className="f-tiptap-commands-list__item-label">
                              {item.title}
                            </span>
                            <span className="f-tiptap-commands-list__item-keymap" data-keymap={item.keymap}>
                            </span>
                          </span>
                        </button>
                      </li>
                    )
                  })}
                </ul>
              </>
            ))}
          </div>
        ) : null}

        <div className="f-tiptap-commands-list__section f-tiptap-commands-list__section--fallback">
          <ul className="f-tiptap-commands-list__section-ul">
            <li className="f-tiptap-commands-list__section-li">
              <span className="f-tiptap-commands-list__item f-tiptap-commands-list__item--fallback">
                <span className="f-tiptap-commands-list__item-inner">
                  <span className="f-tiptap-commands-list__item-label">
                    {translate(TRANSLATIONS, "defaultAction").replace('{query}', this.props.query || "")}
                  </span>
                  <span className="f-tiptap-commands-list__item-keymap">
                    esc
                  </span>
                </span>
              </span>
            </li>
          </ul>
        </div>
      </div>
    );
  }
}

export default CommandsList;
