import React from "react";
import type { Editor } from "@tiptap/react";
import type { Range } from "@tiptap/core";
import { X } from 'lucide-react';

import { type CommandsListProps, type CommandsListState } from "./commands-list";

export class CommandsListBackdrop extends React.Component<
  CommandsListProps,
  CommandsListState
> {
  close () {
    console.log('close')

    this.props.command({
      title: "",
      normalizedTitle: "",
      icon: X,
      key: "commandListBackdrop",
      command: ({ chain }: { chain: FolioEditorCommandChain }) => {
        console.log('commandListBackdrop', this.props.query)
        if (this.props.query) {
          // insert space to disable suggestion
          console.log('insertContent')
          chain.insertContent(` `)
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
