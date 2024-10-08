import { uniqueId } from 'lodash'
import { takeLatest, put, call, select } from 'redux-saga/effects'

import { apiPost } from 'utils/api'

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
const SET_SUBMITTING = 'notesFields/SET_SUBMITTING'

// Actions

export function setNotesFieldsData (data) {
  return { type: SET_NOTES_FIELDS_DATA, data }
}

export function setSubmitting (submitting) {
  return { type: SET_SUBMITTING, submitting }
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

export const notesForTableSelector = (state) => {
  const subState = notesFieldsSelector(state)

  if (subState.showChecked) {
    return subState.notes
  } else {
    return subState.notes.filter((note) => !note.attributes.closed_at)
  }
}

export const notesFieldsSerializedSelector = (state, useUniqueId = false) => {
  const subState = notesFieldsSelector(state)
  const ary = []
  let index = 0

  subState.notes.forEach((note) => {
    index += 1

    const h = {
      id: note.id,
      position: index,
      content: note.attributes.content,
      created_by_id: note.attributes.created_by_id,
      closed_by_id: note.attributes.closed_by_id,
      closed_at: note.attributes.closed_at ? note.attributes.closed_at.toISOString() : null,
      due_at: note.attributes.due_at ? note.attributes.due_at.toISOString() : null
    }

    if (useUniqueId) h.uniqueId = note.uniqueId

    ary.push(h)
  })

  subState.removedIds.forEach((removedId) => {
    index += 1

    const h = {
      id: removedId,
      _destroy: '1'
    }

    ary.push(h)
  })

  return ary
}

// Sagas

function * triggerDirtyFormOrSubmit (action) {
  const notesFields = yield (select(notesFieldsSelector))
  const serialized = yield (select(notesFieldsSerializedSelector))

  if (notesFields.url) {
    try {
      yield put(setSubmitting(true))

      const response = yield call(apiPost, notesFields.url, {
        console_notes_attributes: serialized,
        target_id: notesFields.targetId,
        target_type: notesFields.targetType
      })

      yield put(setNotesFieldsData({ ...response.data.react, submitting: false }))

      if (notesFields.classNameParent && notesFields.classNameTooltipParent) {
        window
          .jQuery(notesFields.domRoot)
          .closest(`.${notesFields.classNameParent}`)
          .trigger('folioConsole:success', response)
          .find(`.${notesFields.classNameTooltipParent}`)
          .html(response.data.catalogue_tooltip)
      }
    } catch (e) {
      yield put(setSubmitting(false))
      window.FolioConsole.Flash.alert(e.message)
    }
  } else {
    const $wrap = window.jQuery('.folio-react-wrap--notes-fields').eq(0)
    $wrap.trigger('folioCustomChange')
    if ($wrap[0]) $wrap[0].dispatchEvent(new window.Event('change', { bubbles: true }))

    yield $wrap
  }
}

function * triggerDirtyFormOrSubmitSaga () {
  yield takeLatest([
    REMOVE_ALL,
    SAVE_FORM,
    REMOVE_NOTE,
    UPDATE_NOTE
  ], triggerDirtyFormOrSubmit)
}

export const notesFieldsSagas = [
  triggerDirtyFormOrSubmitSaga
]

// State

const initialState = {
  domRoot: null,
  notes: [],
  removedIds: [],
  accountId: null,
  paramBase: null,
  label: null,
  showChecked: true,
  form: null,
  errorsHtml: null,
  targetId: null,
  targetType: null,
  url: null,
  submitting: false,
  classNameParent: null,
  classNameTooltipParent: null
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

    case SET_SUBMITTING: {
      return {
        ...state,
        submitting: action.submitting
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
