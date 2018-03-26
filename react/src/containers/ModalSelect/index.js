import React, { Component } from 'react'

import SingleSelect from 'containers/SingleSelect'

const MODAL_SELECTOR = '.folio-console-react-images-modal'

class ModalSelect extends Component {
  state = {
    el: null,
  }

  componentWillMount () {
    let $ = window.jQuery
    if (!$) return

    $(document).on('click', '.folio-console-add-image', (e) => {
      this.setState({ el: e.target })
      $(MODAL_SELECTOR).modal('show')
    })
  }

  selectFile = (file) => {
    if (!this.state.el) return
    let $ = window.jQuery
    if (!$) return

    const $el = $(this.state.el)
    const $fields = $el.siblings('.folio-console-nested-fields-with-images')

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
    const isCover = placementType.match('cover')
    const affix = isCover ? '' : `[${Date.now()}]`
    const prefix = `${name}[${placementType}_attributes]${affix}`

    const $newFile = $(`
      <div class="nested-fields">
        <img src=${window.encodeURI(file.thumb)} alt="" />
        <div class="folio-console-hover-destroy">
          <i class="fa fa-times-circle" data-destroy-association=""></i>
        </div>

        <input type="hidden" name="${prefix}[_destroy]" value="0" />
        <input type="hidden" name="${prefix}[file_id]" value="${file.file_id}" />
        ${isCover ? '' : `<input type="hidden" name="${prefix}[position]" value="${position}" />`}
      </div>
    `)

    $fields.append($newFile)
    $fields.closest('[data-cocoon-single-nested]').trigger('single-nested-change')

    $(MODAL_SELECTOR).modal('hide')
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
