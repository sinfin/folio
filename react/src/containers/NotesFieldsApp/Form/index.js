import React from 'react'
import TextareaAutosize from 'react-autosize-textarea'

class Form extends React.Component {
  state = { content: '', originalContent: '' }

  constructor (props) {
    super(props)
    this.state = { content: props.content, originalContent: props.content }
  }

  save = (e) => {
    this.props.save(this.state.content)
  }

  onChange = (e) => {
    this.setState({ ...this.state, content: e.currentTarget.value })
  }

  onKeyUp = (e) => {
    if (e.key === 'Escape') {
      this.close()
    }
  }

  close = () => {
    if (this.state.content !== this.state.originalContent) {
      if (window.confirm(window.FolioConsole.translations.cancelChanges)) {
        this.props.close()
      }
    } else {
      this.props.close()
    }
  }

  render () {
    return (
      <div className='f-c-r-notes-fields-app-form'>
        <TextareaAutosize
          defaultValue={this.state.content}
          onChange={this.onChange}
          onKeyUp={this.onKeyUp}
          type='text'
          className='form-control f-c-r-notes-fields-app-form__textarea'
          rows={1}
          placeholder={window.FolioConsole.translations.notesFieldsAdd}
          async
          autoFocus
        />

        <button
          type='button'
          className='btn btn-sm btn-primary f-c-r-notes-fields-app-form__button'
          onClick={this.save}
        >
          {window.FolioConsole.translations.save}
        </button>

        <button
          type='button'
          className='fa fa-times text-danger f-c-r-notes-fields-app-form__close'
          onClick={this.close}
        />
      </div>
    )
  }
}

export default Form
