import { mapValues, sortBy, omit } from 'lodash'
import { takeEvery, call, select, put } from 'redux-saga/effects'

import { apiHtmlPost } from 'utils/api'
import arrayMove from 'utils/arrayMove'
import timestamp from 'utils/timestamp'

// Constants

const SET_ATOMS_DATA = 'atoms/SET_ATOMS_DATA'
const NEW_ATOM = 'atoms/NEW_ATOM'
const EDIT_ATOM = 'atoms/EDIT_ATOM'
const REMOVE_ATOM = 'atoms/REMOVE_ATOM'
const SAVE_FORM_ATOM = 'atoms/SAVE_FORM_ATOM'
const CLOSE_FORM_ATOM = 'atoms/CLOSE_FORM_ATOM'
const UPDATE_FORM_ATOM_TYPE = 'atoms/UPDATE_FORM_ATOM_TYPE'
const UPDATE_FORM_ATOM_VALUE = 'atoms/UPDATE_FORM_ATOM_VALUE'
const MOVE_ATOM_TO_INDEX = 'atoms/MOVE_ATOM_TO_INDEX'
const UPDATE_FORM_ATOM_ATTACHMENTS = 'atoms/UPDATE_FORM_ATOM_ATTACHMENTS'
const REMOVE_FORM_ATOM_ATTACHMENT = 'atoms/REMOVE_FORM_ATOM_ATTACHMENT'

// Actions

export function setAtomsData (data) {
  return { type: SET_ATOMS_DATA, data }
}

export function updateFormAtomType (newType, values) {
  return { type: UPDATE_FORM_ATOM_TYPE, newType, values }
}

export function updateFormAtomValue (key, value) {
  return { type: UPDATE_FORM_ATOM_VALUE, key, value }
}

export function newAtom (rootKey, index, atomType) {
  return { type: NEW_ATOM, rootKey, index, atomType }
}

export function editAtom (rootKey, index) {
  return { type: EDIT_ATOM, rootKey, index }
}

export function removeAtom (rootKey, index) {
  return { type: REMOVE_ATOM, rootKey, index }
}

export function moveAtomToIndex (rootKey, index, targetIndex) {
  return { type: MOVE_ATOM_TO_INDEX, rootKey, index, targetIndex }
}

export function closeFormAtom () {
  return { type: CLOSE_FORM_ATOM }
}

export function saveFormAtom () {
  return { type: SAVE_FORM_ATOM }
}

export function updateFormAtomAttachments (attachmentKey, data) {
  return { type: UPDATE_FORM_ATOM_ATTACHMENTS, attachmentKey, data }
}

export function removeFormAtomAttachment (attachmentKey) {
  return { type: REMOVE_FORM_ATOM_ATTACHMENT, attachmentKey }
}

// Selectors

export const atomsSelector = (state) => ({
  ...state.atoms,
  atoms: mapValues(state.atoms.atoms, (collection) => (
    collection.map((atom) => ({
      ...atom,
      meta: state.atoms.structures[atom.type]
    }))
  ))
})

export const atomSelector = (substate, rootKey, index) => {
  const atom = substate.atoms[rootKey][index]

  return {
    ...atom,
    meta: substate.structures[atom.type]
  }
}

export const atomTypesSelector = (state) => {
  const unsorted = Object.keys(state.atoms.structures).map((key) => ({
    key,
    title: state.atoms.structures[key].title
  }))
  return sortBy(unsorted, ['title'])
}

export const serializedAtomsSelector = (state) => {
  const h = {}
  Object.keys(state.atoms.atoms).forEach((rootKey) => {
    h[`${rootKey}_attributes`] = state.atoms.atoms[rootKey].map((atom) => {
      const base = {
        ...atom,
        ...atom.data,
        data: null
      }

      state.atoms.structures[atom.type]['attachments'].forEach(({ key }) => {
        if (!base[key]) return
        base[key] = omit(base[key], ['id', 'file'])
      })
      return base
    })
  })
  return h
}

// Sagas
function * updateAtomPreviews (action) {
  yield put(closeFormAtom())
  const iframe = document.getElementById('f-c-simple-form-with-atoms__iframe')
  iframe.parentElement.classList.add('f-c-simple-form-with-atoms__preview--loading')
  const serializedAtoms = yield select(serializedAtomsSelector)
  const html = yield (call(apiHtmlPost, '/console/atoms_preview/preview', serializedAtoms))
  iframe.contentDocument.body.innerHTML = html
  iframe.contentWindow.postMessage({ type: 'replacedHtml' }, window.origin)
  iframe.parentElement.classList.remove('f-c-simple-form-with-atoms__preview--loading')
}

function * updateAtomPreviewsSaga () {
  yield [
    takeEvery(REMOVE_ATOM, updateAtomPreviews),
    takeEvery(MOVE_ATOM_TO_INDEX, updateAtomPreviews),
    takeEvery(SAVE_FORM_ATOM, updateAtomPreviews)
  ]
}

function * showAtomsForm (action) {
  yield window.jQuery('.f-c-simple-form-with-atoms__form--atoms').addClass('f-c-simple-form-with-atoms__form--active')
}

function * showAtomsFormSaga () {
  yield [
    takeEvery(EDIT_ATOM, showAtomsForm)
  ]
}

function * hideAtomsForm (action) {
  yield window.jQuery('.f-c-simple-form-with-atoms__form--atoms').removeClass('f-c-simple-form-with-atoms__form--active')
}

function * hideAtomsFormSaga () {
  yield takeEvery(CLOSE_FORM_ATOM, hideAtomsForm)
}

export const atomsSagas = [
  updateAtomPreviewsSaga,
  showAtomsFormSaga,
  hideAtomsFormSaga
]

// State

export const initialState = {
  atoms: {},
  destroyedIds: {},
  namespace: null,
  structures: {},
  form: {
    rootKey: null,
    index: null,
    atom: null,
    edit: null
  }
}

// Reducer

function atomsReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ATOMS_DATA:
      return {
        ...state,
        ...action.data
      }

    case NEW_ATOM:
      return {
        ...state,
        form: {
          rootKey: action.rootKey,
          index: action.index,
          edit: false,
          atom: {
            id: null,
            type: action.atomType,
            data: {},
            timestamp: timestamp()
          }
        }
      }

    case EDIT_ATOM:
      return {
        ...state,
        form: {
          rootKey: action.rootKey,
          index: action.index,
          atom: atomSelector(state, action.rootKey, action.index),
          edit: true
        }
      }

    case REMOVE_ATOM: {
      const atom = state.atoms[action.rootKey][action.index]

      if (atom.id) {
        return {
          ...state,
          destroyedIds: {
            ...state.destroyedIds,
            [action.rootKey]: [...state.destroyedIds[action.rootKey], atom.id]
          },
          atoms: {
            ...state.atoms,
            [action.rootKey]: state.atoms[action.rootKey].filter((a, i) => i !== action.index)
          }
        }
      } else {
        return {
          ...state,
          atoms: {
            ...state.atoms,
            [action.rootKey]: state.atoms[action.rootKey].filter((atom, i) => i !== action.index)
          }
        }
      }
    }

    case CLOSE_FORM_ATOM:
      return {
        ...state,
        form: {
          ...initialState.form
        }
      }

    case SAVE_FORM_ATOM: {
      const destroyedIds = { ...state.destroyedIds }

      if (state.form.edit) {
        destroyedIds[state.form.rootKey] = [...state.destroyedIds[state.form.rootKey], state.form.atom.id]
      }

      const atoms = []

      state.atoms[state.form.rootKey].forEach((atom, index) => {
        if (index === state.form.index) {
          atoms.push({
            ...omit(state.form.atom, ['meta', 'id']),
            timestamp: timestamp()
          })

          if (!state.form.edit) {
            atoms.push(atom)
          }
        } else {
          atoms.push(atom)
        }
      })

      return {
        ...state,
        destroyedIds,
        atoms: {
          ...state.atoms,
          [state.form.rootKey]: atoms
        },
        form: {
          ...initialState.form
        }
      }
    }

    case UPDATE_FORM_ATOM_TYPE:
      return {
        ...state,
        form: {
          ...state.form,
          atom: {
            ...state.form.atom,
            type: action.newType,
            data: action.values,
            meta: state.structures[action.newType]
          }
        }
      }

    case UPDATE_FORM_ATOM_VALUE:
      return {
        ...state,
        form: {
          ...state.form,
          atom: {
            ...state.form.atom,
            data: {
              ...state.form.atom.data,
              [action.key]: action.value
            }
          }
        }
      }

    case MOVE_ATOM_TO_INDEX:
      return {
        ...state,
        atoms: {
          ...state.atoms,
          [action.rootKey]: arrayMove(state.atoms[action.rootKey], action.index, action.targetIndex)
        }
      }

    case UPDATE_FORM_ATOM_ATTACHMENTS: {
      return {
        ...state,
        form: {
          ...state.form,
          atom: {
            ...state.form.atom,
            [action.attachmentKey]: {
              ...state.form.atom[action.attachmentKey],
              ...action.data
            }
          }
        }
      }
    }

    case REMOVE_FORM_ATOM_ATTACHMENT: {
      return {
        ...state,
        form: {
          ...state.form,
          atom: omit(state.form.atom, [action.attachmentKey])
        }
      }
    }

    default:
      return state
  }
}

export default atomsReducer
