import React from 'react'
import TextareaAutosize from 'react-autosize-textarea'

class Form extends React.Component {
  state = { content: '' }

  save = (e) => {
    this.props.save(this.state.content)
  }

  onChange = (e) => {
    this.setState({ content: e.currentTarget.value })
  }

  render () {
    return (
      <div className='f-c-r-notes-fields-app-form'>
        <TextareaAutosize
          defaultValue={this.state.content}
          onChange={this.onChange}
          type='text'
          className='form-control f-c-r-notes-fields-app-form__textarea'
          rows={1}
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
      </div>
    )
  }
}

export default Form
