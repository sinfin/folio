import { apiPost } from 'utils/api'
import { call, takeEvery, put } from 'redux-saga/effects'

// Constants

const OPEN_FILE_MODAL = 'fileModal/OPEN_FILE_MODAL'
const CLOSE_FILE_MODAL = 'fileModal/CLOSE_FILE_MODAL'
const CHANGE_FILE_MODAL_TAGS = 'fileModal/CHANGE_FILE_MODAL_TAGS'
const UPDATE_FILE_THUMBNAIL = 'fileModal/UPDATE_FILE_THUMBNAIL'
const UPDATED_FILE_MODAL_FILE = 'fileModal/UPDATED_FILE_MODAL_FILE'

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

export function updateFileThumbnail (filesKey, file, thumbKey, params) {
  return { type: UPDATE_FILE_THUMBNAIL, filesKey, file, thumbKey, params }
}

export function updatedFileModalFile (file) {
  return { type: UPDATED_FILE_MODAL_FILE, file }
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

function * updateFileThumbnailPerform (action) {
  if (action.filesKey !== 'images') return
  const filesUrl = `/console/api/${action.filesKey}/${action.file.id}/update_file_thumbnail`
  const response = yield call(apiPost, filesUrl, { ...action.params, thumb_key: action.thumbKey })
  yield put(updatedFileModalFile(response.data))
}

function * updateFileThumbnailSaga () {
  yield takeEvery(UPDATE_FILE_THUMBNAIL, updateFileThumbnailPerform)
}

export const fileModalSagas = [
  loadFileForModalSaga,
  updateFileThumbnailSaga
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

    case UPDATE_FILE_THUMBNAIL:
      return {
        ...state,
        file: {
          ...state.file,
          attributes: {
            ...state.file.attributes,
            thumbnail_sizes: {
              ...state.file.attributes.thumbnail_sizes,
              [action.thumbKey]: {
                ...state.file.attributes.thumbnail_sizes[action.thumbKey],
                ...action.params,
                _saving: true
              }
            }
          }
        }
      }

    case UPDATED_FILE_MODAL_FILE: {
      if (state.file.id === action.file.id) {
        return {
          ...state,
          file: action.file
        }
      } else {
        return state
      }
    }

    default:
      return state
  }
}

export default modalReducer
