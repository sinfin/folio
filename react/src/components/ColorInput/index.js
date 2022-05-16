import React from 'react'
import { Input } from 'reactstrap'

class ColorInput extends React.PureComponent {
  constructor (props) {
    super(props)
    this.inputRef = React.createRef()
  }

  focus () {
  }

  componentDidMount () {
    if (window.folioConsoleInitColorPicker) {
      window.folioConsoleInitColorPicker(this.inputRef.current, {
        change: (color) => {
          this.props.onChange(color.toRgbString())
        }
      })
    }
  }

  componentWillUnmount () {
    if (window.folioConsoleUnbindColorPicker) {
      window.folioConsoleUnbindColorPicker(this.inputRef.current)
    }
  }

  render () {
    return (
      <Input
        type='text'
        name={this.props.name}
        defaultValue={this.props.defaultValue}
        placeholder={this.props.placeholder}
        innerRef={this.inputRef}
        invalid={this.props.invalid}
        className='f-c-color-input'
      />
    )
  }
}

export default ColorInput
