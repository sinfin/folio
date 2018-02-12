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

    const $last = $el.siblings('.nested-fields').last()
    let position = 0

    if ($last.length) {
      position = Number($last.find('input').filter(function () {
        return $(this).attr('name').indexOf('position') !== -1
      }).val()) + 1
      if (Number.isNaN(position)) {
        position = 0
      }
    }

    const name = $el.parents('.nested-fields').find('input[type="hidden"]').attr('name')
    const prefix = `${name.match(/\w+\[\w+\]\[\w+\]/)}[file_placements_attributes][]`
    const $newFile = $(`
      <div class="nested-fields">
        <img class="img-responsive" src=${file.thumb} alt="" />
        <a href="#" class="btn btn-danger destroy-image">&times;</a>
        <input type="hidden" name="${prefix}[_destroy]" value="0" />
        <input type="hidden" name="${prefix}[file_id]" value="${file.file_id}" />
        <input type="hidden" name="${prefix}[position]" value="${position}" />
      </div>
    `)

    $newFile.insertBefore($el)

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
