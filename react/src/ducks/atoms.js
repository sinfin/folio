import { mapValues, sortBy } from 'lodash'
import { takeEvery, call, select } from 'redux-saga/effects'

import { apiHtmlPost } from 'utils/api'

// Constants

const SET_ATOMS_DATA = 'atoms/SET_ATOMS_DATA'
const UPDATE_ATOM_VALUE = 'atoms/UPDATE_ATOM_VALUE'
const UPDATE_ATOM_TYPE = 'atoms/UPDATE_ATOM_TYPE'

// Actions

export function setAtomsData (data) {
  return { type: SET_ATOMS_DATA, data }
}

export function updateAtomValue (rootKey, index, key, value) {
  return { type: UPDATE_ATOM_VALUE, rootKey, index, key, value }
}

export function updateAtomType (rootKey, index, newType, values) {
  return { type: UPDATE_ATOM_TYPE, rootKey, index, newType, values }
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
    h[`${rootKey}_attributes`] = state.atoms.atoms[rootKey].map((atom) => ({
      ...atom,
      ...atom.data,
      data: null
    }))
  })
  return h
}

// Sagas
function * updateAtomPreviews (action) {
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
    takeEvery(UPDATE_ATOM_VALUE, updateAtomPreviews),
    takeEvery(UPDATE_ATOM_TYPE, updateAtomPreviews)
  ]
}

export const atomsSagas = [
  updateAtomPreviewsSaga
]

// State

export const initialState = {
  atoms: {},
  namespace: null,
  structures: {}
}

// Reducer

function atomsReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ATOMS_DATA:
      return {
        ...state,
        ...action.data
      }

    case UPDATE_ATOM_VALUE:
      return {
        ...state,
        atoms: {
          ...state.atoms,
          [action.rootKey]: state.atoms[action.rootKey].map((atom, index) => {
            if (index === action.index) {
              return {
                ...atom,
                data: {
                  ...atom.data,
                  [action.key]: action.value
                }
              }
            } else {
              return { ...atom }
            }
          })
        }
      }

    case UPDATE_ATOM_TYPE:
      return {
        ...state,
        atoms: {
          ...state.atoms,
          [action.rootKey]: state.atoms[action.rootKey].map((atom, index) => {
            if (index === action.index) {
              return {
                ...atom,
                type: action.newType,
                data: action.values
              }
            } else {
              return { ...atom }
            }
          })
        }
      }

    default:
      return state
  }
}

export default atomsReducer
