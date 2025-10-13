import React from "react";
import translate from "@/lib/i18n";
import { X } from 'lucide-react';

import "./folio-tiptap-commands-list.scss";

const TRANSLATIONS = {
  cs: {
    defaultAction: "Napsat /{query} do obsahu",
    defaultBlankAction: "Zavřít nabídku",
  },
  en: {
    defaultAction: "Type /{query} to content",
    defaultBlankAction: "Close menu",
  },
};

export interface FolioTiptapCommandsListProps {
  items: FolioEditorCommandGroupForSuggestion[];
  command: (item: FolioEditorCommandForSuggestion) => void;
  query: string;
}

export interface FolioTiptapCommandsListState {
  selectedIndex: number;
}

export class FolioTiptapCommandsList extends React.Component<
  FolioTiptapCommandsListProps,
  FolioTiptapCommandsListState
> {
  constructor(props: FolioTiptapCommandsListProps) {
    super(props);

    this.state = {
      selectedIndex: 0,
    };
  }

  onEscape() {
    // Always pass a valid FolioEditorCommandForSuggestion with a title
    this.props.command({
      title: "",
      normalizedTitle: "",
      icon: X,
      key: "commandListEscape",
      command: ({ chain }: { chain: FolioEditorCommandChain }) => {
        if (this.props.query) {
          // insert space to disable suggestion
          chain.insertContent(`/${this.props.query} `)
        }
      },
    });
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
      let itemsCount = 0;
      this.props.items.forEach((group) => {
        itemsCount += group.commandsForSuggestion.length;
      });

      newIndex = itemsCount - 1;
    }

    this.setSelectedIndex(newIndex);
  }

  downHandler() {
    let itemsCount = 0;
    this.props.items.forEach((group) => {
      itemsCount += group.commandsForSuggestion.length;
    });

    let newIndex = this.state.selectedIndex + 1;

    if (newIndex >= itemsCount) {
      newIndex = 0;
    }

    this.setSelectedIndex(newIndex);
  }

  enterHandler() {
    let index = -1;
    let targetItem: FolioEditorCommandForSuggestion | null = null;

    this.props.items.forEach((group) => {
      if (targetItem) return;

      group.commandsForSuggestion.forEach((item) => {
        if (targetItem) return;
        index += 1;

        if (index === this.state.selectedIndex) {
          targetItem = item;
        }
      });
    });

    if (targetItem) {
      this.selectItem(targetItem);
    }
  }

  selectItem(item: FolioEditorCommandForSuggestion) {
    if (item) {
      this.props.command(item);
    }
  }

  componentDidUpdate(
    prevProps: FolioTiptapCommandsListProps,
  ) {
    let previousItemsCount = 0;
    prevProps.items.forEach((group) => {
      previousItemsCount += group.commandsForSuggestion.length;
    });

    let itemsCount = 0;
    this.props.items.forEach((group) => {
      itemsCount += group.commandsForSuggestion.length;
    });

    if (itemsCount !== previousItemsCount) {
      this.setState({ selectedIndex: 0 });
    }
  }

  render() {
    let index = -1;

    return (
      <div className="f-tiptap-commands-list">
        {this.props.items.length > 0 ? (
          <div className="f-tiptap-commands-list__section f-tiptap-commands-list__section--scroll">
            {this.props.items.map((group: FolioEditorCommandGroupForSuggestion) => (
              <React.Fragment key={group.title}>
                <div className="f-tiptap-commands-list__section-heading">
                  {group.title}
                </div>

                <ul className="f-tiptap-commands-list__section-ul">
                  {group.commandsForSuggestion.map((commandsForSuggestion: FolioEditorCommandForSuggestion) => {
                    index += 1;

                    const ItemIcon = commandsForSuggestion.icon;
                    const itemIndex = index

                    return (
                      <li
                        className="f-tiptap-commands-list__section-li"
                        key={`${group.title}-${commandsForSuggestion.title}`}
                      >
                        <button
                          type="button"
                          className="f-tiptap-commands-list__item f-tiptap-commands-list__item--active"
                          data-selected={String(
                            index === this.state.selectedIndex,
                          )}
                          onClick={() => this.selectItem(commandsForSuggestion)}
                          onMouseOver={() => this.setSelectedIndex(itemIndex)}
                        >
                          <span className="f-tiptap-commands-list__item-inner">
                            {ItemIcon ? (
                              <ItemIcon className="f-tiptap-commands-list__item-icon" />
                            ) : null}
                            <span className="f-tiptap-commands-list__item-label">
                              {commandsForSuggestion.title}
                            </span>
                            <span
                              className="f-tiptap-commands-list__item-keymap"
                              data-keymap={commandsForSuggestion.keymap}
                            ></span>
                          </span>
                        </button>
                      </li>
                    );
                  })}
                </ul>
              </React.Fragment>
            ))}
          </div>
        ) : null}

        <div className="f-tiptap-commands-list__section f-tiptap-commands-list__section--fallback">
          <ul className="f-tiptap-commands-list__section-ul">
            <li className="f-tiptap-commands-list__section-li">
              <span className="f-tiptap-commands-list__item f-tiptap-commands-list__item--fallback">
                <span className="f-tiptap-commands-list__item-inner">
                  <span className="f-tiptap-commands-list__item-label">
                    {this.props.query
                      ? translate(TRANSLATIONS, "defaultAction").replace(
                          "{query}",
                          this.props.query,
                        )
                      : translate(TRANSLATIONS, "defaultBlankAction")}
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

export default FolioTiptapCommandsList;
