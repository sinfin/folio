import React from 'react'
import { Input } from 'reactstrap'

import preventEnterSubmit from 'utils/preventEnterSubmit'

class DateInput extends React.PureComponent {
  constructor (props) {
    super(props)
    this.inputRef = React.createRef()
  }

  onChange = () => {
    const that = this
    setTimeout(() => {
      const val = that.inputRef.current.value
      that.props.onChange(val === '' ? null : val)
    }, 0)
  }

  focus () {
    this.inputRef.current.focus()
  }

  componentDidMount () {
    if (this.props.type === 'date' && window.folioConsoleInitDatePicker) {
      window.folioConsoleInitDatePicker(this.inputRef.current)
    } else if (this.props.type === 'datetime' && window.folioConsoleInitDateTimePicker) {
      window.folioConsoleInitDateTimePicker(this.inputRef.current)
    }

    window.jQuery(this.inputRef.current).on('dp.change', this.onChange)
  }

  componentWillUnmount () {
    window.jQuery(this.inputRef.current).off('dp.change', this.onChange)
    if (window.folioConsoleUnbindDatePicker) {
      window.folioConsoleUnbindDatePicker(this.inputRef.current)
    }
  }

  defaultValue () {
    if (this.props.defaultValue) {
      return new Date(this.props.defaultValue)
    } else {
      return ''
    }
  }

  render () {
    return (
      <div className='d-flex flex-row justify-content-between align-items-center'>
        <Input
          type='text'
          name={this.props.name}
          defaultValue={this.defaultValue()}
          onKeyPress={preventEnterSubmit}
          placeholder={this.props.placeholder}
          innerRef={this.inputRef}
          invalid={this.props.invalid}
          data-date={this.props.defaultValue}
        />
      </div>
    )
  }
}

export default DateInput
