import React from 'react'
import { Input } from 'reactstrap'

class AutocompleteInput extends React.PureComponent {
  constructor (props) {
    super(props)
    this.inputRef = React.createRef()
  }

  componentDidMount () {
    let $input
    if (window.folioConsoleBindRemoteAutocomplete) {
      $input = window.jQuery(this.inputRef.current)
      window.folioConsoleBindRemoteAutocomplete($input)
      $input.on('remoteAutocompleteDidSelect', this.props.onChange)
    }
  }

  componentWillUnmount () {
    let $input
    if (window.folioConsoleUnbindRemoteAutocomplete) {
      $input = window.jQuery(this.inputRef.current)
      window.folioConsoleUnbindRemoteAutocomplete($input)
      $input.off('remoteAutocompleteDidSelect')
    }
  }

  render () {
    return (
      <Input
        type='text'
        value={this.props.value || ''}
        onChange={this.props.onChange}
        name={this.props.name}
        innerRef={this.inputRef}
        autoFocus={this.props.autoFocus}
        placeholder={this.props.placeholder}
        data-remote-autocomplete={this.props.url}
      />
    )
  }
}

export default AutocompleteInput
