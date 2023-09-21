import React from 'react'
import TextareaAutosize from 'react-autosize-textarea'

import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import I18N from '../i18n'

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
      if (window.confirm(window.Folio.i18n(I18N, 'cancelChanges'))) {
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
          placeholder={window.Folio.i18n(I18N, 'notesFieldsAdd')}
          async
          autoFocus
        />

        <FolioConsoleUiButton
          class='f-c-r-notes-fields-app-form__button'
          variant='primary'
          onClick={this.save}
          label={window.Folio.i18n(I18N, 'save')}
        />

        <FolioConsoleUiButton
          variant='danger'
          className='f-c-r-notes-fields-app-form__close'
          icon='close'
          onClick={this.close}
        />
      </div>
    )
  }
}

export default Form
