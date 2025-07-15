import React, { useState, useEffect, useCallback } from "react";

interface CommandItem {
  title: string;
  [key: string]: any;
}

interface CommandsListProps {
  items: CommandItem[];
  command: (item: CommandItem) => void;
}

export class CommandsList extends React.Component {
  constructor() {
    super();

    this.state = {
      selectedIndex: 0,
    };
  }

  onKeyDown({ event }) {
    if (event.key === "ArrowUp") {
      this.upHandler();
      return true;
    }

    if (event.key === "ArrowDown") {
      this.downHandler();
      return true;
    }

    if (event.key === "Enter") {
      this.enterHandler();
      return true;
    }

    return false;
  }

  setSelectedIndex (selectedIndex) {
    this.setState({ selectedIndex });
  }

  upHandler() {
    this.setSelectedIndex((this.state.selectedIndex + this.props.items.length - 1) % this.props.items.length);
  }

  downHandler() {
    this.setSelectedIndex((this.state.selectedIndex + 1) % this.props.items.length)
  }

  enterHandler() {
    this.selectItem(this.state.selectedIndex);
  }

  selectItem(index) {
    const item = this.props.items[index];

    if (item) {
      this.props.command(item);
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.items.length !== this.props.items.length) {
      this.setState({ selectedIndex: 0 });
    }
  }

  render () {
    return (
      <div className="dropdown-menu">
        {this.props.items.length > 0 ? (
          this.props.items.map((item, index) => (
            <button
              key={index}
              className={index === this.state.selectedIndex ? "is-selected" : ""}
              onClick={() => this.selectItem(index)}
            >
              {item.title}
            </button>
          ))
        ) : (
          <div className="item">No result</div>
        )}
      </div>
    );
  }
};

export default CommandsList;
