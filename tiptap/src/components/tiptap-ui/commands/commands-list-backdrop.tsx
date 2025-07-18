import React from "react";
import type { Editor } from "@tiptap/react";
import type { Range } from "@tiptap/core";

import { type CommandsListProps, type CommandsListState } from "./commands-list";

export class CommandsListBackdrop extends React.Component<
  CommandsListProps,
  CommandsListState
> {
  close () {
    // Always pass a valid CommandItem with a title
    this.props.command({
      title: "",
      command: ({
        editor,
        range,
      }: {
        editor: Editor;
        range: Range;
      }) => {
        if (this.props.query) {
          // insert space to disable suggestion
          editor.chain().focus().insertContent(" ").run();
        } else {
          // remove current paragraph
          editor.chain().focus().deleteRange(range).run();
        }
      },
    });
  }

  render() {
    return (
      <div className="f-tiptap-commands-list-backdrop" onClick={() => this.close()} />
    );
  }
}

export default CommandsListBackdrop;
