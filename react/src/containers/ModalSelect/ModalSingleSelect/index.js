import React from 'react'

import SingleSelect from 'containers/SingleSelect'

import { EVENT_NAME } from './constants'
import ModalSelect from '../'

class ModalSingleSelect extends ModalSelect {
  selector () {
    return this.selectingDocument() ? '.folio-console-add-document' : '.folio-console-add-image'
  }

  fileModalSelector () {
    if (this.selectingDocument()) {
      return '.folio-console-react-picker__edit--document'
    } else {
      return '.folio-console-react-picker__edit--image'
    }
  }

  eventName () {
    const append = this.selectingDocument() ? 'Folio::Document' : 'Folio::Image'
    return `${EVENT_NAME}/${append}`
  }

  jQueryModal () {
    const $ = window.jQuery
    return $('.folio-console-react-modal')
      .filter(`[data-klass="${this.props.fileType}"]`)
      .filter('[data-multi="false"]')
  }

  fileTemplate (file, prefix) {
    if (this.selectingDocument()) {
      return `
        <div class="folio-console-thumbnail__inner">
          <strong class="folio-console-thumbnail__title">${file.attributes.file_name}</strong>
          <input type="hidden" name="${prefix}[title]" value="" data-file-name="${file.attributes.file_name}" />
          <button class="f-c-file-list__file-btn f-c-file-list__file-btn--edit btn btn-secondary fa fa-edit folio-console-react-picker__edit folio-console-react-picker__edit--document" type="button"></button>
          <button class="f-c-file-list__file-btn f-c-file-list__file-btn--destroy btn btn-danger fa fa-times" data-destroy-association="" type="button"></button>
        </div>
      `
    } else {
      return `
        <div class="folio-console-thumbnail__inner">
          <div class="folio-console-thumbnail__img-wrap">
            <img class="folio-console-thumbnail__img" src=${window.encodeURI(file.attributes.thumb)} alt="" />
            <button class="f-c-file-list__file-btn f-c-file-list__file-btn--edit btn btn-secondary fa fa-edit folio-console-react-picker__edit folio-console-react-picker__edit--image" type="button"></button>
            <button class="f-c-file-list__file-btn f-c-file-list__file-btn--destroy btn btn-danger fa fa-times" data-destroy-association="" type="button"></button>
          </div>
        </div>

        <input type="hidden" name="${prefix}[alt]" value="" />
        <small class="folio-console-thumbnail__alt">alt:</small>
      `
    }
  }

  selectFile = (filesKey, file) => {
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

    const $el = $(this.state.el)
    const $wrap = $el.closest('.folio-console-react-picker')
    const $fields = $wrap.find('.folio-console-react-picker__files')

    const name = this.inputName($el)
    const placementKey = $fields.data('placement-key')
    const prefix = `${name}[${placementKey}_attributes]`

    const $newFile = $(`
      <div class="nested-fields folio-console-thumbnail folio-console-thumbnail--${this.selectingDocument() ? 'document' : 'image'}">
        <input type="hidden" name="${prefix}[_destroy]" value="0" />
        <input type="hidden" name="${prefix}[file_id]" value="${file.id}" />
        ${this.fileTemplate(file, prefix)}
      </div>
    `)

    $newFile
      .find('.folio-console-react-picker__edit')
      .attr('data-file', JSON.stringify(file))

    $fields.html($newFile)
    $fields.closest('[data-cocoon-single-nested]').trigger('single-nested-change')

    this.jQueryModal().modal('hide')
  }

  render () {
    return (
      <SingleSelect
        selectFile={this.selectFile}
        filesKey={this.props.filesKey}
        inModal
      />
    )
  }
}

export default ModalSingleSelect
