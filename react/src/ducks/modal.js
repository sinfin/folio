// Constants

const OPEN_MODAL = 'app/OPEN_MODAL'
const SAVE_MODAL = 'app/SAVE_MODAL'
const CANCEL_MODAL = 'app/CANCEL_MODAL'
const CHANGE_MODAL_TAGS = 'app/CHANGE_MODAL_TAGS'

// Actions

export function openModal (file) {
  return { type: OPEN_MODAL, file }
}

export function saveModal (file) {
  return { type: SAVE_MODAL, file }
}

export function cancelModal () {
  return { type: CANCEL_MODAL }
}

export function changeModalTags (tags) {
  return { type: CHANGE_MODAL_TAGS, tags }
}

// Selectors

export const modalSelector = (state) => state.modal

// State

const initialState = {
  file: null,
  newTags: null,
}

// Reducer

function modalReducer (state = initialState, action) {
  switch (action.type) {
    case OPEN_MODAL:
      return {
        ...state,
        file: action.file,
      }

    case CANCEL_MODAL:
      return initialState

    case CHANGE_MODAL_TAGS:
      return {
        ...state,
        newTags: action.tags,
      }

    default:
      return state
  }
}

export default modalReducer
