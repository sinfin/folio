import React from 'react'
import { Input } from 'reactstrap'

class RichTextEditor extends React.PureComponent {
  constructor (props) {
    super(props)
    this.editorRef = React.createRef()
  }

  componentDidMount () {
    if (window.folioConsoleInitRedactor) {
      window.folioConsoleInitRedactor(this.editorRef.current, {}, {
        callbacks: {
          changed: this.props.onChange
        }
      })
    }
  }

  componentWillUnmount () {
    if (window.folioConsoleDestroyRedactor) {
      window.folioConsoleDestroyRedactor(this.editorRef.current)
    }
  }

  focus () {
    this.editorRef.current.focus()
  }

  render () {
    return (
      <Input
        type='textarea'
        defaultValue={this.props.defaultValue}
        innerRef={this.editorRef}
      />
    )
  }
}

export default RichTextEditor
