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
      this.props.loadFiles(this.props.fileType, this.props.filesUrl)
      this.onOpen(e.target)
      this.jQueryModal().modal('show')
    })

    if (this.fileModalSelector()) {
      $(document).on('click', this.fileModalSelector(), (e) => {
        e.stopPropagation()
        this.props.openFileModal(this.props.fileType, this.props.filesUrl, $(e.target).data('file'))
      })
    }

    const eventName = this.eventName()
    if (eventName) {
      window.addEventListener(eventName, (e) => {
        console.log(e)
        this.setState({ el: e.target })
        this.props.loadFiles(this.props.fileType, this.props.filesUrl)
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

  selectingImage () {
    return this.props.reactType === 'image'
  }

  render () {
    return null
  }
}

export default ModalSelect
