import React, { Component } from 'react'

import SingleSelect from 'containers/SingleSelect'
import truncate from 'utils/truncate';

class ModalSelect extends Component {
  state = {
    el: null,
  }

  componentWillMount () {
    const $ = window.jQuery
    if (!$) return

    const selector = this.selectingDocument() ? '.folio-console-add-document' : '.folio-console-add-image'

    $(document).on('click', selector, (e) => {
      this.setState({ el: e.target })
      this.props.loadFiles()
      this.jQueryModal().modal('show')
    })
  }

  selectingDocument () {
    return this.props.fileType === 'Folio::Document'
  }

  jQueryModal () {
    const $ = window.jQuery
    const selector = this.selectingDocument() ? '.folio-console-react-documents-modal' : '.folio-console-react-images-modal'
    return $(selector)
  }

  fileTemplate (file) {
    if (this.selectingDocument()) {
      return `
        <div class="folio-console-document-thumbnail">
          <i class="fa fa-file-o"></i>
          <strong>${truncate(file.file_name)}</strong>
        </div>
      `
    } else {
      return `<img src=${window.encodeURI(file.thumb)} alt="" />`
    }
  }

  selectFile = (file) => {
    if (!this.state.el) return
    let $ = window.jQuery
    if (!$) return

    const $el = $(this.state.el)
    const $fields = $el.siblings('.folio-console-nested-fields-with-files')

    const $last = $fields.find('.nested-fields').last()
    let position = 0

    if ($last.length) {
      position = Number($last.find('input').filter(function () {
        return $(this).attr('name').indexOf('position') !== -1
      }).val()) + 1

      if (Number.isNaN(position)) {
        position = 0
      }
    }

    const $nestedInput = $el.closest('.nested-fields').find('input[type="hidden"]')
    let name
    if ($nestedInput.length) {
      name = $nestedInput.attr('name').match(/\w+\[\w+\]\[\w+\]/)
    } else {
      const $genericInput = $el.closest('form').find('.form-control[name*="["]').first()
      name = $genericInput.attr('name').split('[')[0]
    }

    const placementType = $fields.data('placement-type')
    const hasOne = $fields.data('has-one')
    const affix = hasOne ? '' : `[${Date.now()}]`
    const prefix = `${name}[${placementType}_attributes]${affix}`

    const $newFile = $(`
      <div class="nested-fields">
        ${this.fileTemplate(file)}

        <div class="folio-console-hover-destroy">
          <i class="fa fa-times-circle" data-destroy-association=""></i>
        </div>

        <input type="hidden" name="${prefix}[_destroy]" value="0" />
        <input type="hidden" name="${prefix}[file_id]" value="${file.file_id}" />
        ${hasOne ? '' : `<input type="hidden" name="${prefix}[position]" value="${position}" />`}
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

export default ModalSelect
