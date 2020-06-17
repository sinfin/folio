import { Component } from 'react'

class ModalSelect extends Component {
  state = {
    el: null
  }

  componentWillMount () {
    const $ = window.jQuery
    if (!$) return

    $(document).on('click', this.selector(), (e) => {
      this.setState({ el: e.target })
      this.props.loadFiles(this.props.fileType)
      this.onOpen(e.target)
      this.jQueryModal().modal('show')
    })

    if (this.fileModalSelector()) {
      $(document).on('click', this.fileModalSelector(), (e) => {
        e.stopPropagation()
        this.props.openFileModal(this.props.filesKey, $(e.target).data('file'))
      })
    }

    const eventName = this.eventName()
    if (eventName) {
      $(document).on(eventName, (e, eventData) => {
        this.setState(eventData)
        this.props.loadFiles(this.props.fileType)
        this.onOpen(e.target)
        this.jQueryModal().modal('show')
      })
    }
  }

  onOpen (el) {
  }

  selector () {
    throw new Error('Not implemented')
  }

  fileModalSelector () {
  }

  eventName () {
  }

  selectingDocument () {
    return this.props.fileType === 'Folio::Document'
  }

  fileTemplate (file, prefix) {
    throw new Error('Not implemented')
  }

  inputName ($el) {
    const $nestedInput = $el.closest('.nested-fields').find('input[type="hidden"]')
    let name

    if ($nestedInput.length) {
      const match = $nestedInput.attr('name').match(/(\w+\[\w+\](\[\w+\])*)(?:\[\w+\])(?:\[\d+\])?(?:\[\w+\])?/)
      if (match) name = match[1]
    }

    if (!name) {
      const $genericInput = $el.closest('form').find('.form-control[name*="["]').first()
      name = $genericInput.attr('name').split('[')[0]
    }

    return name
  }

  render () {
    return null
  }
}

export default ModalSelect
