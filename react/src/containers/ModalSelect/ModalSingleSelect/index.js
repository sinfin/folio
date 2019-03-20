import React from 'react'

import SingleSelect from 'containers/SingleSelect'
import truncate from 'utils/truncate';

import ModalSelect from '../';

class ModalSingleSelect extends ModalSelect {
  selector () {
    return this.selectingDocument() ? '.folio-console-add-document' : '.folio-console-add-image'
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
          <i class="folio-console-thumbnail__fa-icon fa fa-file-o"></i>
          <strong class="folio-console-thumbnail__title">${truncate(file.file_name)}</strong>
          <input type="hidden" name="${prefix}[title]" value="" data-file-name="${file.file_name}" />
          <div class="folio-console-hover-destroy">
            <i class="fa fa-edit folio-console-thumbnail__title-edit"></i>
            <i class="fa fa-times-circle" data-destroy-association></i>
          </div>
        </div>
      `
    } else {
      return `
        <div class="folio-console-thumbnail__inner">
          <div class="folio-console-thumbnail__img-wrap">
            <img class="folio-console-thumbnail__img" src=${window.encodeURI(file.thumb)} alt="" />
            <div class="folio-console-hover-destroy">
              <i class="fa fa-times-circle" data-destroy-association></i>
            </div>
          </div>
        </div>

        <input type="hidden" name="${prefix}[alt]" value="" />
        <small class="folio-console-thumbnail__alt">alt:</small>
      `
    }
  }

  selectFile = (file) => {
    if (!this.state.el) return
    let $ = window.jQuery
    if (!$) return

    const $el = $(this.state.el)
    const $wrap = $el.closest('.folio-console-react-picker')
    const $fields = $wrap.find('.folio-console-react-picker__files')

    const name = this.inputName($el)
    const placementKey = $fields.data('placement-key')
    const placementType = $fields.data('placement-type')
    console.log(placementType)
    const prefix = `${name}[${placementKey}_attributes]`

    const $newFile = $(`
      <div class="nested-fields folio-console-thumbnail folio-console-thumbnail--${this.selectingDocument() ? 'document' : 'image'}">
        <input type="hidden" name="${prefix}[_destroy]" value="0" />
        <input type="hidden" name="${prefix}[file_id]" value="${file.id}" />
        <input type="hidden" name="${prefix}[type]" value="${placementType}" />
        ${this.fileTemplate(file, prefix)}
      </div>
    `)

    $fields.append($newFile)
    $fields.closest('[data-cocoon-single-nested]').trigger('single-nested-change')

    this.jQueryModal().modal('hide')
  }

  render () {
    return (
      <SingleSelect
        selectFile={this.selectFile}
      />
    )
  }
}

export default ModalSingleSelect
