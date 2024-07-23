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

  onChange = (e) => {
    this.props.onChange(e.target.value)
  }

  focus () {
    this.inputRef.current.focus()
  }

  render () {
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
          defaultValue={this.props.defaultValue}
          data-controller='f-input-date-time'
          data-f-input-date-time-type-value={this.props.type}
        />
      </div>
    )
  }
}

export default DateInput
