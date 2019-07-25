import React from 'react'
import { Editor, EditorState } from 'draft-js'
import { convertToHTML, convertFromHTML } from 'draft-convert'

class RichTextEditor extends React.PureComponent {
  constructor (props) {
    super(props)

    this.state = {
      editorState: EditorState.createWithContent(convertFromHTML(props.defaultValue)),
      html: props.defaultValue
    }
  }

  onChange = (editorState) => {
    this.setState({
      editorState,
      html: convertToHTML(editorState.getCurrentContent())
    })
  }

  render () {
    return (
      <React.Fragment>
        <Editor editorState={this.state.editorState} onChange={this.onChange} />
        <input type='hidden' value={this.state.html} name={this.props.name} />
      </React.Fragment>
    )
  }
}

export default RichTextEditor
