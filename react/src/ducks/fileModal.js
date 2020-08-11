import { call, takeEvery, put, select } from 'redux-saga/effects'

import { apiGet, apiPost, apiFilePost } from 'utils/api'
import { flashError } from 'utils/flash'
import { updatedFiles, UPDATE_FILE_SUCCESS, UPDATE_FILE_FAILURE } from 'ducks/files'

// Constants

const OPEN_FILE_MODAL = 'fileModal/OPEN_FILE_MODAL'
const CLOSE_FILE_MODAL = 'fileModal/CLOSE_FILE_MODAL'
const UPDATE_FILE_THUMBNAIL = 'fileModal/UPDATE_FILE_THUMBNAIL'
const UPDATED_FILE_MODAL_FILE = 'fileModal/UPDATED_FILE_MODAL_FILE'
const UPLOAD_NEW_FILE_INSTEAD = 'fileModal/UPLOAD_NEW_FILE_INSTEAD'
const UPLOAD_NEW_FILE_INSTEAD_SUCCESS = 'fileModal/UPLOAD_NEW_FILE_INSTEAD_SUCCESS'
const MARK_MODAL_FILE_AS_UPDATING = 'fileModal/MARK_MODAL_FILE_AS_UPDATING'
const MARK_MODAL_FILE_AS_UPDATED = 'fileModal/MARK_MODAL_FILE_AS_UPDATED'
const LOADED_FILE_MODAL_PLACEMENTS = 'fileModal/LOADED_FILE_MODAL_PLACEMENTS'
const CHANGE_FILE_PLACEMENTS_PAGE = 'fileModal/CHANGE_FILE_PLACEMENTS_PAGE'

// Actions

export function openFileModal (fileType, filesUrl, file) {
  return { type: OPEN_FILE_MODAL, fileType, filesUrl, file }
}

export function closeFileModal () {
  return { type: CLOSE_FILE_MODAL }
}

export function updateFileThumbnail (fileType, filesUrl, file, thumbKey, params) {
  return { type: UPDATE_FILE_THUMBNAIL, fileType, filesUrl, file, thumbKey, params }
}

export function updatedFileModalFile (file) {
  return { type: UPDATED_FILE_MODAL_FILE, file }
}

export function uploadNewFileInstead (fileType, filesUrl, file, fileIo) {
  return { type: UPLOAD_NEW_FILE_INSTEAD, fileType, filesUrl, file, fileIo }
}

export function uploadNewFileInsteadSuccess (file) {
  return { type: UPLOAD_NEW_FILE_INSTEAD_SUCCESS, file }
}

export function markModalFileAsUpdating (file) {
  return { type: MARK_MODAL_FILE_AS_UPDATING, file }
}

export function markModalFileAsUpdated (file) {
  return { type: MARK_MODAL_FILE_AS_UPDATED, file }
}

export function loadedFileModalPlacements (file, filePlacements, meta) {
  return { type: LOADED_FILE_MODAL_PLACEMENTS, file, filePlacements, meta }
}

export function changeFilePlacementsPage (file, page) {
  return { type: CHANGE_FILE_PLACEMENTS_PAGE, file, page }
}

// Selectors

export const fileModalSelector = (state) => state.fileModal

// Sagas
function * updateFileThumbnailPerform (action) {
  if (action.file.attributes.react_type !== 'image') return

  try {
    const url = `${action.filesUrl}/${action.file.id}/update_file_thumbnail`
    const response = yield call(apiPost, url, { ...action.params, thumb_key: action.thumbKey })
    yield put(updatedFileModalFile(response.data))
  } catch (e) {
    flashError(e.message)
  }
}

function * updateFileThumbnailSaga () {
  yield takeEvery(UPDATE_FILE_THUMBNAIL, updateFileThumbnailPerform)
}

function * uploadNewFileInsteadPerform (action) {
  try {
    const url = `${action.filesUrl}/${action.file.id}/change_file`
    const data = new FormData()
    data.append('file[attributes][file]', action.fileIo)
    const response = yield call(apiFilePost, url, data)
    yield put(updatedFileModalFile(response.data))
    yield put(updatedFiles(action.fileType, [response.data]))
    yield put(uploadNewFileInsteadSuccess(response.data))
  } catch (e) {
    flashError(e.message)
  }
}

function * uploadNewFileInsteadSaga () {
  yield takeEvery(UPLOAD_NEW_FILE_INSTEAD, uploadNewFileInsteadPerform)
}

function * handleFileUpdatePerform (action) {
  const fileModal = yield select(fileModalSelector)

  if (action.file.id === fileModal.file.id) {
    yield put(markModalFileAsUpdated(action.response || action.file))
  }
}

function * handleFileUpdateSaga () {
  yield [
    takeEvery(UPDATE_FILE_SUCCESS, handleFileUpdatePerform),
    takeEvery(UPDATE_FILE_FAILURE, handleFileUpdatePerform)
  ]
}

function * openFileModalPerform (action) {
  try {
    const url = `/console/api/files/${action.file.id}/file_placements`
    const response = yield call(apiGet, url)
    yield put(loadedFileModalPlacements(action.file, response.data, response.meta))
  } catch (e) {
    flashError(e.message)
  }
}

function * openFileModalSaga () {
  yield takeEvery(OPEN_FILE_MODAL, openFileModalPerform)
}

function * changeFilePlacementsPagePerform (action) {
  try {
    const url = `/console/api/files/${action.file.id}/file_placements?page=${action.page}`
    const response = yield call(apiGet, url)
    yield put(loadedFileModalPlacements(action.file, response.data, response.meta))
  } catch (e) {
    flashError(e.message)
  }
}

function * changeFilePlacementsPageSaga () {
  yield takeEvery(CHANGE_FILE_PLACEMENTS_PAGE, changeFilePlacementsPagePerform)
}

export const fileModalSagas = [
  updateFileThumbnailSaga,
  uploadNewFileInsteadSaga,
  handleFileUpdateSaga,
  openFileModalSaga,
  changeFilePlacementsPageSaga
]

// State

const initialState = {
  file: null,
  fileType: null,
  uploadingNew: false,
  updating: false,
  filePlacements: {
    loading: false,
    records: [],
    pagination: {
      page: null,
      pages: null
    }
  }
}

// Reducer

function modalReducer (state = initialState, action) {
  switch (action.type) {
    case OPEN_FILE_MODAL:
      return {
        ...initialState,
        file: action.file,
        fileType: action.fileType,
        filesUrl: action.filesUrl,
        filePlacements: {
          ...initialState.filePlacements,
          loading: true
        }
      }

    case CLOSE_FILE_MODAL:
      return initialState

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
      if (state.file && state.file.id === action.file.id) {
        return {
          ...state,
          file: action.file
        }
      } else {
        return state
      }
    }

    case UPLOAD_NEW_FILE_INSTEAD:
      return {
        ...state,
        uploadingNew: true
      }

    case UPLOAD_NEW_FILE_INSTEAD_SUCCESS: {
      if (state.file && state.file.id === action.file.id) {
        return {
          ...state,
          uploadingNew: false
        }
      } else {
        return state
      }
    }

    case MARK_MODAL_FILE_AS_UPDATING: {
      if (state.file && state.file.id === action.file.id) {
        return {
          ...state,
          updating: true
        }
      } else {
        return state
      }
    }

    case MARK_MODAL_FILE_AS_UPDATED: {
      if (state.file && state.file.id === action.file.id) {
        return {
          ...state,
          file: action.file,
          updating: false
        }
      } else {
        return state
      }
    }

    case LOADED_FILE_MODAL_PLACEMENTS: {
      if (state.file && state.file.id === action.file.id) {
        return {
          ...state,
          filePlacements: {
            loading: false,
            records: action.filePlacements,
            pagination: action.meta
          }
        }
      } else {
        return state
      }
    }

    case CHANGE_FILE_PLACEMENTS_PAGE: {
      if (state.file && state.file.id === action.file.id) {
        return {
          ...state,
          filePlacements: {
            ...state.filePlacements,
            loading: true
          }
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
