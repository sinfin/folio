import { mapValues } from 'lodash'

// Constants

const SET_ATOMS_DATA = 'atoms/SET_ATOMS_DATA'
const UPDATE_ATOM_VALUE = 'atoms/UPDATE_ATOM_VALUE'

// Actions

export function setAtomsData (data) {
  return { type: SET_ATOMS_DATA, data }
}

export function updateAtomValue (rootKey, index, key, value) {
  return { type: UPDATE_ATOM_VALUE, rootKey, index, key, value }
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

    default:
      return state
  }
}

export default atomsReducer
