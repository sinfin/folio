import React from 'react'
import TextareaAutosize from 'react-autosize-textarea'

import FolioUiIcon from 'components/FolioUiIcon'
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

        <div className='f-c-r-notes-fields-app-form__buttons'>
          <span
            className='f-c-r-notes-fields-app-form__button f-c-r-notes-fields-app-form__button--save text-success'
            onClick={this.save}
            label={window.Folio.i18n(I18N, 'save')}
          >
            <FolioUiIcon name='checkbox_marked' height={24} />
          </span>

          <span
            className='f-c-r-notes-fields-app-form__button f-c-r-notes-fields-app-form__button--close text-danger'
            icon='close'
            onClick={this.close}
          >
            <FolioUiIcon name='close' height={24} />
          </span>
        </div>
      </div>
    )
  }
}

export default Form
