import { uniqueId } from 'lodash'
import { takeLatest } from 'redux-saga/effects'

// Constants

const SET_NOTES_FIELDS_DATA = 'notesFields/SET_NOTES_FIELDS_DATA'
const UPDATE_SHOW_CHECKED = 'notesFields/UPDATE_SHOW_CHECKED'
const REMOVE_ALL = 'notesFields/REMOVE_ALL'
const INIT_NEW_NOTE = 'notesFields/INIT_NEW_NOTE'
const SAVE_FORM = 'notesFields/SAVE_FORM'
const CLOSE_FORM = 'notesFields/CLOSE_FORM'
const EDIT_NOTE = 'notesFields/EDIT_NOTE'
const REMOVE_NOTE = 'notesFields/REMOVE_NOTE'
const UPDATE_NOTE = 'notesFields/UPDATE_NOTE'

// Actions

export function setNotesFieldsData (data) {
  return { type: SET_NOTES_FIELDS_DATA, data }
}

export function updateShowChecked (showChecked) {
  return { type: UPDATE_SHOW_CHECKED, showChecked }
}

export function removeAll () {
  return { type: REMOVE_ALL }
}

export function initNewNote () {
  return { type: INIT_NEW_NOTE }
}

export function saveForm (content) {
  return { type: SAVE_FORM, content }
}

export function closeForm (content) {
  return { type: CLOSE_FORM }
}

export function editNote (note) {
  return { type: EDIT_NOTE, note }
}

export function removeNote (note) {
  return { type: REMOVE_NOTE, note }
}

export function updateNote (note, attributes) {
  return { type: UPDATE_NOTE, note, attributes }
}

// Selectors

export const notesFieldsSelector = (state) => state.notesFields

// Sagas

function * triggerDirtyForm (action) {
  const $wrap = window.jQuery('.folio-react-wrap--notes-fields')
  $wrap.trigger('folioCustomChange')
  $wrap.closest('.f-c-simple-form-with-atoms__form, .f-c-dirty-simple-form').trigger('change')
  yield $wrap
}

function * triggerDirtyFormSaga () {
  yield takeLatest([
    REMOVE_ALL,
    SAVE_FORM,
    REMOVE_NOTE,
    UPDATE_NOTE
  ], triggerDirtyForm)
}

export const notesFieldsSagas = [
  triggerDirtyFormSaga
]

// State

const initialState = {
  notes: [],
  removedIds: [],
  accountId: null,
  paramBase: null,
  label: null,
  showChecked: true,
  form: null,
  errorsHtml: null
}

// Reducer

function notesFieldsReducer (state = initialState, action) {
  switch (action.type) {
    case SET_NOTES_FIELDS_DATA: {
      const notes = []
      const removedIds = []

      action.data.notes.forEach((note) => {
        if (note.attributes._destroy) {
          removedIds.push(note.id)
        } else {
          notes.push({
            ...note,
            uniqueId: uniqueId(),
            attributes: {
              ...note.attributes,
              closed_at: note.attributes.closed_at ? (new Date(Date.parse(note.attributes.closed_at))) : null,
              due_at: note.attributes.due_at ? (new Date(Date.parse(note.attributes.due_at))) : null
            }
          })
        }
      })

      return {
        ...state,
        ...action.data,
        notes,
        removedIds
      }
    }

    case UPDATE_SHOW_CHECKED: {
      return {
        ...state,
        showChecked: action.showChecked
      }
    }

    case REMOVE_ALL: {
      const removedIds = state.removedIds

      state.notes.forEach((note) => {
        if (note.id) removedIds.push(note.id)
      })

      return {
        ...state,
        removedIds,
        notes: []
      }
    }

    case INIT_NEW_NOTE: {
      return {
        ...state,
        form: {
          existingUniqueId: null,
          content: ''
        }
      }
    }

    case SAVE_FORM: {
      if (state.form.existingUniqueId) {
        return {
          ...state,
          form: null,
          notes: state.notes.map((note) => {
            if (note.uniqueId === state.form.existingUniqueId) {
              return {
                ...note,
                attributes: {
                  ...note.attributes,
                  content: action.content
                }
              }
            } else {
              return note
            }
          })
        }
      } else {
        return {
          ...state,
          form: null,
          notes: [
            ...state.notes,
            {
              id: null,
              uniqueId: uniqueId(),
              attributes: {
                content: action.content,
                created_by_id: state.accountId,
                due_at: null,
                closed_at: null
              }
            }
          ]
        }
      }
    }

    case UPDATE_NOTE: {
      return {
        ...state,
        form: null,
        notes: state.notes.map((note) => {
          if (note.uniqueId === action.note.uniqueId) {
            return {
              ...note,
              attributes: {
                ...note.attributes,
                ...action.attributes
              }
            }
          } else {
            return note
          }
        })
      }
    }

    case CLOSE_FORM: {
      return {
        ...state,
        form: null
      }
    }

    case EDIT_NOTE: {
      return {
        ...state,
        form: {
          existingUniqueId: action.note.uniqueId,
          content: action.note.attributes.content
        }
      }
    }

    case REMOVE_NOTE: {
      const removedIds = state.removedIds
      const notes = []

      state.notes.forEach((note) => {
        if (note.uniqueId === action.note.uniqueId) {
          if (note.id) removedIds.push(note.id)
        } else {
          notes.push(note)
        }
      })

      return {
        ...state,
        notes,
        removedIds
      }
    }

    default:
      return state
  }
}

export default notesFieldsReducer
