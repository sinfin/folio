import { Component } from 'react'

class ModalSelect extends Component {
  state = {
    el: null,
  }

  componentWillMount () {
    const $ = window.jQuery
    if (!$) return

    $(document).on('click', this.selector(), (e) => {
      this.setState({ el: e.target })
      this.props.loadFiles()
      this.onOpen(e.target)
      this.jQueryModal().modal('show')
    })
  }

  onOpen (el) {
  }

  selector () {
    throw new Error('Not implemented')
  }

  selectingDocument () {
    return this.props.fileType === 'Folio::Document'
  }

  fileTemplate (file, prefix) {
    throw new Error('Not implemented')
  }

  render () {
    return null
  }
}

export default ModalSelect
