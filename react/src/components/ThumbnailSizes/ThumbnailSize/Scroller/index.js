import React from 'react'

import Picture from 'components/Picture'

class Scroller extends React.Component {
  constructor (props) {
    super(props)

    const imageStyle = { cursor: 'move' }
    const fileWidth = this.props.file.attributes.file_width
    const fileHeight = this.props.file.attributes.file_height
    const imageRatio = fileWidth / fileHeight
    const wrapRatio = this.props.width / this.props.height

    if (imageRatio > wrapRatio) {
      imageStyle.height = this.props.height
      imageStyle.width = fileWidth * this.props.height / fileHeight
    } else {
      imageStyle.width = this.props.width
      imageStyle.height = fileHeight * this.props.width / fileWidth
    }

    let x = props.thumb.x
    if (props.thumb.x === null || props.thumb.x === undefined) {
      x = Math.abs((imageStyle.width - this.props.width) / 2 / imageStyle.width)
    }

    let y = props.thumb.y
    if (props.thumb.y === null || props.thumb.y === undefined) {
      y = Math.abs((imageStyle.height - this.props.height) / 2 / imageStyle.height)
    }

    this.state = { imageStyle, x, y }
    this.scrollRef = React.createRef()
  }

  componentDidMount () {
    if (!this.scrollRef.current) return

    this.scrollRef.current.scrollTop = this.state.y * this.state.imageStyle.height
    this.scrollRef.current.scrollLeft = this.state.x * this.state.imageStyle.width

    window.jQuery(this.scrollRef.current).kinetic({
      moved: this.handleScroll
    })
  }

  componentWillUnmount () {
    if (!this.scrollRef.current) return
    window.jQuery(this.scrollRef.current).kinetic('destroy')
  }

  save = () => {
    this.props.save({ x: this.state.x, y: this.state.y })
  }

  handleScroll = () => {
    const ref = this.scrollRef.current

    this.setState({
      ...this.state,
      y: ref.scrollTop / ref.clientHeight,
      x: ref.scrollLeft / ref.clientWidth
    })
  }

  render () {
    return (
      <div>
        <div ref={this.scrollRef} style={{ width: this.props.width, height: this.props.height, overflow: 'hidden' }}>
          <Picture file={this.props.file} imageStyle={this.state.imageStyle} />
        </div>

        <div className='mt-2 pt-1 small'>{this.props.thumbKey}</div>

        <div className='d-flex flex-wrap'>
          <button className='btn btn-sm btn-secondary mt-2 mr-2' onClick={this.props.close}>{window.FolioConsole.translations.cancel}</button>
          <button className='btn btn-sm btn-primary mt-2' onClick={this.save}>{window.FolioConsole.translations.saveOffset}</button>
        </div>
      </div>
    )
  }
}

export default Scroller
