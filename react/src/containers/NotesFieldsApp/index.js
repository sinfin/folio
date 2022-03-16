import React from 'react'
import { connect } from 'react-redux'

import {
  notesFieldsSelector,
  initNewNote,
  updateShowChecked,
  removeAll,
  saveForm
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
    this.props.dispatch(saveForm(content))
  }

  render () {
    const { notesFields } = this.props

    return (
      <div className='f-c-r-notes-fields-app form-group'>
        <div className='f-c-r-notes-fields-app__header'>
          <label className='f-c-r-notes-fields-app__header-label'>{notesFields.label}</label>

          {notesFields.notes.length ? (
            <div className='f-c-r-notes-fields-app__header-buttons'>
              <button type='button' className='btn btn-sm btn-info' onClick={this.toggleShowChecked}>
                {notesFields.showChecked ? window.FolioConsole.translations.notesFieldsHide : window.FolioConsole.translations.notesFieldsShow}
              </button>

              <button type='button' className='btn btn-sm btn-info ml-2' onClick={this.removeAll}>
                {window.FolioConsole.translations.notesFieldsDelete}
              </button>
            </div>
          ) : null}
        </div>

        <Table notes={notesFields.notes} />

        <div className='mt-2'>
          {notesFields.form ? (
            <Form content={notesFields.form.content} save={this.saveForm} />
          ) : (
            <button type='button' className='btn btn-sm btn-secondary' onClick={this.initNewNote}>
              {window.FolioConsole.translations.notesFieldsAdd}
            </button>
          )}
        </div>

        <Serialized notesFields={notesFields} />
      </div>
    )
  }
}

const mapStateToProps = (state, props) => ({
  notesFields: notesFieldsSelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(NotesFields)
