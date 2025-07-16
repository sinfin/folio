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
    this.setSelectedIndex(
      (this.state.selectedIndex + this.props.items.length - 1) %
        this.props.items.length,
    );
  }

  downHandler() {
    this.setSelectedIndex(
      (this.state.selectedIndex + 1) % this.props.items.length,
    );
  }

  enterHandler() {
    this.selectItem(this.state.selectedIndex);
  }

  selectItem(index: number) {
    const item = this.props.items[index];

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
    return (
      <div className="f-tiptap-commands-list">
        <ul className="f-tiptap-commands-list__section">
          {this.props.items.length > 0 ? (
            this.props.items.map((item: CommandItem, index: number) => (
              <li className="f-tiptap-commands-list__section-li">
                <button
                  key={index}
                  type="button"
                  className="f-tiptap-commands-list__item f-tiptap-commands-list__item--active"
                  data-selected={String(index === this.state.selectedIndex)}
                  onClick={() => this.selectItem(index)}
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
            ))
          ) : null}
        </ul>

        <ul className="f-tiptap-commands-list__section f-tiptap-commands-list__section--fallback">
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
    );
  }
}

export default CommandsList;
