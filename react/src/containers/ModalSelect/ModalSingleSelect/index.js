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

    const $el = $(this.state.el)
    const $wrap = $el.closest('.folio-console-react-picker')
    const $fields = $wrap.find('.folio-console-react-picker__files')

    const name = this.inputName($el)
    const placementKey = $fields.data('placement-key')
    const attributesKey = `[${placementKey}_attributes]`
    const prefix = `${name}${attributesKey}`.replace(`${attributesKey}${attributesKey}`, attributesKey)

    const $newFile = $(`
      <div class="nested-fields folio-console-thumbnail folio-console-thumbnail--${this.selectingImage() ? 'image' : 'document'} f-c-add-file cursor-pointer" data-file-type="${fileType}">
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

    const $setting = $fields.closest('[data-atom-setting]')

    window.postMessage({ type: 'setFormAsDirty' }, window.origin)

    if ($setting.length) {
      window.postMessage({ type: 'refreshPreview' })
    }

    this.jQueryModal().modal('hide')
  }

  render () {
    return (
      <SingleSelect
        selectFile={this.selectFile}
        fileType={this.props.fileType}
        filesUrl={this.props.filesUrl}
        inModal
      />
    )
  }
}

export default ModalSingleSelect
