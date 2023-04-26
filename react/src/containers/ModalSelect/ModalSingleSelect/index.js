import React from 'react'

import SingleSelect from 'containers/SingleSelect'

import { EVENT_NAME } from './constants'
import ModalSelect from '../'

class ModalSingleSelect extends ModalSelect {
  selector () {
    return `.f-c-add-file[data-file-type="${this.props.fileType}"]`
  }

  fileModalSelector () {
    return `.folio-console-react-picker__edit[data-file-type="${this.props.fileType}"]`
  }

  eventName () {
    return `${EVENT_NAME}/${this.props.fileType}`
  }

  jQueryModal () {
    const $ = window.jQuery
    return $('.f-c-r-modal').filter(`[data-klass="${this.props.fileType}"]`)
  }

  fileTemplate (file, prefix) {
    if (this.selectingImage()) {
      return `
        <div class="folio-console-thumbnail__inner">
          <div class="folio-console-thumbnail__img-wrap">
            <img class="folio-console-thumbnail__img" src=${window.encodeURI(file.attributes.thumb)} alt="" />
            <button class="f-c-file-list__file-btn f-c-file-list__file-btn--edit btn btn-secondary fa fa-edit folio-console-react-picker__edit" data-file-type="${this.props.fileType}" type="button"></button>
            <button class="f-c-file-list__file-btn f-c-file-list__file-btn--destroy btn btn-danger fa fa-times" data-destroy-association="" type="button"></button>
          </div>
        </div>

        <input type="hidden" name="${prefix}[alt]" value="" />
        <small class="folio-console-thumbnail__alt">alt:</small>
      `
    } else {
      return `
        <div class="folio-console-thumbnail__inner">
          <strong class="folio-console-thumbnail__title">${file.attributes.file_name}</strong>
          <input type="hidden" name="${prefix}[title]" value="" data-file-name="${file.attributes.file_name}" />
          <button class="f-c-file-list__file-btn f-c-file-list__file-btn--edit btn btn-secondary fa fa-edit folio-console-react-picker__edit" data-file-type="${this.props.fileType}" type="button"></button>
          <button class="f-c-file-list__file-btn f-c-file-list__file-btn--destroy btn btn-danger fa fa-times" data-destroy-association="" type="button"></button>
        </div>
      `
    }
  }

  selectFile = (fileType, file) => {
    const $ = window.jQuery
    if (!$) return

    if (this.state.triggerEvent) {
      $(document).trigger(this.state.triggerEvent, [{
        attachmentKey: this.state.attachmentKey,
        data: {
          file_id: file.id,
          file
        },
        index: this.state.index
      }])
      return this.jQueryModal().modal('hide')
    }

    if (!this.state.el) return

    console.log({
      bubbles: true,
      detail: { file }
    })

    this.state.el.dispatchEvent(new window.CustomEvent(`folioConsoleModalSingleSelect/${this.props.fileType}/selected`, {
      bubbles: true,
      detail: { file }
    }))

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
        inModal
      />
    )
  }
}

export default ModalSingleSelect
