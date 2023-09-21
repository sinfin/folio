import React, { Component } from 'react'

import SingleSelect from 'containers/SingleSelect'

export const EVENT_NAME_BASE = 'folioConsoleModalSingleSelect'

class ModalSingleSelect extends Component {
  state = { el: null }

  componentDidMount () {
    window.addEventListener(`${EVENT_NAME_BASE}/${this.props.fileType}/showFileModal`, (e) => {
      this.props.openFileModal(this.props.fileType, this.props.filesUrl, e.detail.file, e.detail.autoFocusField)
    })

    window.addEventListener(`${EVENT_NAME_BASE}/${this.props.fileType}/showModal`, (e) => {
      this.setState({ el: e.target })
      this.props.loadFiles(this.props.fileType, this.props.filesUrl)
      this.jQueryModal().modal('show')
    })
  }

  fileModalSelector () {
    return `.folio-console-react-picker__edit[data-file-type="${this.props.fileType}"]`
  }

  jQueryModal () {
    const $ = window.jQuery
    return $('.f-c-r-modal').filter(`[data-klass="${this.props.fileType}"]`)
  }

  selectFile = (fileType, file) => {
    const $ = window.jQuery
    if (!$) return

    if (this.state.el) {
      this.state.el.dispatchEvent(new window.CustomEvent(`${EVENT_NAME_BASE}/${this.props.fileType}/selected`, {
        bubbles: true,
        detail: { file }
      }))
    }

    window.postMessage({ type: 'setFormAsDirty' }, window.origin)

    this.jQueryModal().modal('hide')
  }

  render () {
    return (
      <SingleSelect
        selectFile={this.selectFile}
        fileType={this.props.fileType}
        filesUrl={this.props.filesUrl}
        taggable={this.props.taggable}
        reactType={this.props.reactType}
        inModal
      />
    )
  }
}

export default ModalSingleSelect
