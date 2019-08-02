import React from 'react'
import { Editor, EditorState } from 'draft-js'
import { convertToHTML, convertFromHTML } from 'draft-convert'

class RichTextEditor extends React.PureComponent {
  constructor (props) {
    super(props)

    this.editorRef = React.createRef()

    this.state = {
      editorState: EditorState.createWithContent(convertFromHTML(props.defaultValue || ''))
    }
  }

  onChange = (editorState) => {
    this.setState({ editorState })
    this.props.onChange(convertToHTML(editorState.getCurrentContent()))
  }

  focus () {
    this.editorRef.current.focus()
  }

  render () {
    return (
      <Editor
        editorState={this.state.editorState}
        onChange={this.onChange}
        ref={this.editorRef}
      />
    )
  }
}

export default RichTextEditor
