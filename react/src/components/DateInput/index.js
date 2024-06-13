import React from 'react'
import { Input } from 'reactstrap'

import preventEnterSubmit from 'utils/preventEnterSubmit'

class DateInput extends React.PureComponent {
  constructor (props) {
    super(props)
    this.inputRef = React.createRef()
  }

  componentDidMount () {
    if (this.unbindInput) this.unbindInput()

    this.inputRef.current.addEventListener('change', this.onChange)

    this.unbindInput = () => {
      this.inputRef.current.removeEventListener('change', this.onChange)
      delete this.unbindInput
    }
  }

  componentWillUnmount () {
    if (this.unbindInput) this.unbindInput()
  }

  formatDate (date, delimiter = '-') {
    const options = { day: "2-digit", month: "2-digit", year: "numeric"}
    const dateObj = new Date(date)

    return dateObj.toLocaleDateString("cs-CZ", options)
  }

  onChange = (event) => {
    let date = event.target.folioInputTempusDominus.viewDate

    date = this.formatDate(date)
    date = date.split('. ').reverse().join('-')

    this.props.onChange(date)
  }

  focus () {
    this.inputRef.current.focus()
  }

  render () {
    let defaultValue

    if (this.props.defaultValue && this.props.defaultValue !== '') {
      defaultValue = this.formatDate(this.props.defaultValue)
    }

    return (
      <div className='d-flex flex-row justify-content-between align-items-center'>
        <Input
          type='text'
          name={this.props.name}
          onKeyPress={preventEnterSubmit}
          onChange={this.props.onChange}
          placeholder={this.props.placeholder}
          innerRef={this.inputRef}
          invalid={this.props.invalid}
          defaultValue={defaultValue || ''}
          data-controller='f-input-date-time'
          data-f-input-date-time-type-value={this.props.type}
        />
      </div>
    )
  }
}

export default DateInput
