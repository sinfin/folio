import React from 'react'
import { Input } from 'reactstrap'

class UrlInput extends React.PureComponent {
  constructor (props) {
    super(props)
    this.inputRef = React.createRef()
  }

  componentDidMount () {
    if (!this.inputRef.current) return

    this.boundHandleChange = (e) => {
      this.props.onValueChange(e.target.dataset.value)
    }

    this.inputRef.current.addEventListener('change', this.boundHandleChange)
  }

  componentWillUnmount () {
    if (!this.inputRef.current) return

    if (this.boundHandleChange) {
      this.inputRef.current.removeEventListener('change', this.boundHandleChange)
      delete this.boundHandleChange
    }
  }

  render () {
    return (
      <Input
        name={this.props.key}
        defaultValue={this.props.defaultValue}
        onChange={this.props.onChange}
        onKeyPress={this.props.onKeyPress}
        invalid={this.props.invalid}
        innerRef={this.inputRef}
      />
    )
  }
}

export default UrlInput
