import { takeEvery } from 'redux-saga/effects'

// Constants

const OPEN_FILE_MODAL = 'app/OPEN_FILE_MODAL'
const CLOSE_FILE_MODAL = 'app/CLOSE_FILE_MODAL'
const CHANGE_FILE_MODAL_TAGS = 'app/CHANGE_FILE_MODAL_TAGS'

// Actions

export function openFileModal (filesKey, file) {
  return { type: OPEN_FILE_MODAL, filesKey, file }
}

export function closeFileModal () {
  return { type: CLOSE_FILE_MODAL }
}

export function changeFileModalTags (tags) {
  return { type: CHANGE_FILE_MODAL_TAGS, tags }
}

// Selectors

export const fileModalSelector = (state) => state.fileModal

// Sagas
function * loadFileForModal (action) {
  // used to update atom previews via the data-atom-setting functionality
  yield window.jQuery('.f-c-js-atoms-placement-setting.folio-react-wrap').trigger('folioCustomChange')
}

function * loadFileForModalSaga () {
  yield takeEvery(OPEN_FILE_MODAL, loadFileForModal)
}

export const fileModalSagas = [
  loadFileForModalSaga
]

// State

const initialState = {
  file: null,
  filesKey: null,
  newTags: null,
  loading: false,
  loaded: false
}

// Reducer

function modalReducer (state = initialState, action) {
  switch (action.type) {
    case OPEN_FILE_MODAL:
      return {
        ...state,
        file: action.file,
        filesKey: action.filesKey,
        loading: true
      }

    case CLOSE_FILE_MODAL:
      return initialState

    case CHANGE_FILE_MODAL_TAGS:
      return {
        ...state,
        newTags: action.tags
      }

    default:
      return state
  }
}

export default modalReducer
