import React from "react";
import { X } from 'lucide-react';

import { type FolioTiptapCommandsListProps, type FolioTiptapCommandsListState } from "./folio-tiptap-commands-list";

export class FolioTiptapCommandsListBackdrop extends React.Component<
  FolioTiptapCommandsListProps,
  FolioTiptapCommandsListState
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

export default FolioTiptapCommandsListBackdrop;
