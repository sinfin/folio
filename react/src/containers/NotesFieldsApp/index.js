import React from 'react'
import { connect } from 'react-redux'

import {
  notesFieldsSelector,
  notesForTableSelector,
  notesFieldsSerializedSelector,
  initNewNote,
  updateShowChecked,
  removeAll,
  saveForm,
  closeForm,
  editNote,
  removeNote,
  updateNote
} from 'ducks/notesFields'

import Form from './Form'
import Table from './Table'
import Serialized from './Serialized'

class NotesFields extends React.Component {
  toggleShowChecked = () => {
    this.props.dispatch(updateShowChecked(!this.props.notesFields.showChecked))
  }

  removeAll = () => {
    if (window.confirm(window.FolioConsole.translations.confirmation)) {
      this.props.dispatch(removeAll())
    }
  }

  initNewNote = () => {
    if (this.props.notesFields.form === null) this.props.dispatch(initNewNote())
  }

  saveForm = (content) => {
    if (content === '') {
      this.props.dispatch(closeForm())
    } else {
      this.props.dispatch(saveForm(content))
    }
  }

  closeForm = () => {
    this.props.dispatch(closeForm())
  }

  editNote = (note) => {
    if (this.props.notesFields.form === null) this.props.dispatch(editNote(note))
  }

  removeNote = (note) => {
    if (window.confirm(window.FolioConsole.translations.confirmation)) {
      this.props.dispatch(removeNote(note))
    }
  }

  toggleClosedAt = (note) => {
    const attributes = {}

    if (note.attributes.closed_at) {
      attributes.closed_at = null
      attributes.closed_by_id = null
    } else {
      attributes.closed_at = new Date()
      attributes.closed_by_id = this.props.notesFields.accountId
    }

    this.props.dispatch(updateNote(note, attributes))
  }

  changeDueDate = (note, dueAt) => {
    this.props.dispatch(updateNote(note, { due_at: dueAt }))
  }

  render () {
    const { notesFields, notesForTable } = this.props

    return (
      <div className='f-c-r-notes-fields-app form-group'>
        <div className='f-c-r-notes-fields-app__header'>
          <label className='f-c-r-notes-fields-app__header-label'>{notesFields.label}</label>

          {notesFields.notes.length ? (
            <div className='f-c-r-notes-fields-app__header-buttons'>
              <button type='button' className='btn btn-sm btn-info' onClick={this.toggleShowChecked}>
                {notesFields.showChecked ? window.FolioConsole.translations.notesFieldsHide : window.FolioConsole.translations.notesFieldsShow}
              </button>

              <button type='button' className='btn btn-sm btn-info ms-2' onClick={this.removeAll}>
                {window.FolioConsole.translations.notesFieldsDelete}
              </button>
            </div>
          ) : null}
        </div>

        <div className='f-c-r-notes-fields-app__bottom'>
          <Table
            notesForTable={notesForTable}
            currentlyEditting={!!notesFields.form}
            currentlyEdittingUniqueId={notesFields.form ? notesFields.form.existingUniqueId : null}
            editNote={this.editNote}
            removeNote={this.removeNote}
            toggleClosedAt={this.toggleClosedAt}
            changeDueDate={this.changeDueDate}
          />

          <div className='mt-2'>
            {notesFields.form ? (
              <Form content={notesFields.form.content} save={this.saveForm} close={this.closeForm} />
            ) : (
              <button type='button' className='btn btn-sm btn-secondary' onClick={this.initNewNote}>
                {window.FolioConsole.translations.notesFieldsAdd}
              </button>
            )}
          </div>

          {notesFields.errorsHtml ? (
            <div dangerouslySetInnerHTML={{ __html: notesFields.errorsHtml }} />
          ) : null}

          <span
            className={`folio-loader f-c-r-notes-fields-app__loader ${notesFields.submitting ? 'f-c-r-notes-fields-app__loader--active' : 'f-c-r-notes-fields-app__loader--inactive'}`}
          />
        </div>

        <Serialized paramBase={notesFields.paramBase} serializedNotes={this.props.serializedNotes} />
      </div>
    )
  }
}

const mapStateToProps = (state, props) => ({
  notesFields: notesFieldsSelector(state),
  notesForTable: notesForTableSelector(state),
  serializedNotes: notesFieldsSerializedSelector(state, true)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(NotesFields)
