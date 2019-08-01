import { apiGet, apiPut } from 'utils/api'
import { flashError } from 'utils/flash'
import { takeLatest, takeEvery, call, put, select } from 'redux-saga/effects'
import { filter, find } from 'lodash'

import { fileTypeSelector } from 'ducks/app'
import { makeFilteredFilesSelector } from 'ducks/filters'
import { makeUploadsSelector } from 'ducks/uploads'
import { makeSelectedFileIdsSelector } from 'ducks/filePlacements'

// Constants

const GET_FILES = 'files/GET_FILES'
const GET_FILES_SUCCESS = 'files/GET_FILES_SUCCESS'
const UPLOADED_FILE = 'files/UPLOADED_FILE'
const THUMBNAIL_GENERATED = 'files/THUMBNAIL_GENERATED'
const UPDATE_FILE = 'files/UPDATE_FILE'
const UPDATE_FILE_SUCCESS = 'files/UPDATE_FILE_SUCCESS'
const UPDATE_FILE_FAILURE = 'files/UPDATE_FILE_FAILURE'
const UPDATED_FILES = 'files/UPDATED_FILES'

// Actions

export function getFiles (filesKey) {
  return { type: GET_FILES, filesKey }
}

export function getFilesSuccess (filesKey, records) {
  return { type: GET_FILES_SUCCESS, filesKey, records }
}

export function uploadedFile (filesKey, file) {
  return { type: UPLOADED_FILE, filesKey, file }
}

export function thumbnailGenerated (filesKey, temporaryUrl, url) {
  return { type: THUMBNAIL_GENERATED, filesKey, temporaryUrl, url }
}

export function updatedFiles (filesKey, files) {
  return { type: UPDATED_FILES, filesKey, files }
}

export function updateFile (filesKey, file, attributes) {
  return { type: UPDATE_FILE, filesKey, file, attributes }
}

export function updateFileSuccess (filesKey, file, response) {
  return { type: UPDATE_FILE_SUCCESS, filesKey, file, response }
}

export function updateFileFailure (filesKey, file) {
  return { type: UPDATE_FILE_FAILURE, filesKey, file }
}

// Sagas

function * getFilesPerform (action) {
  try {
    const fileType = yield select(fileTypeSelector)
    const filesUrl = fileType === 'Folio::Document' ? '/console/api/documents' : '/console/api/images'
    const records = yield call(apiGet, filesUrl)
    yield put(getFilesSuccess(action.filesKey, records.data))
  } catch (e) {
    flashError(e.message)
  }
}

function * getFilesSaga () {
  yield takeLatest(GET_FILES, getFilesPerform)
}

function * updateFilePerform (action) {
  try {
    const { file, attributes } = action
    const fileType = yield select(fileTypeSelector)
    const fileUrl = fileType === 'Folio::Document' ? `/console/api/documents/${file.id}` : `/console/api/images/${file.id}`
    const data = {
      file: {
        id: file.id,
        attributes
      }
    }
    const response = yield call(apiPut, fileUrl, data)
    yield put(updateFileSuccess(action.filesKey, action.file, response.data))
  } catch (e) {
    flashError(e.message)
    yield put(updateFileFailure(action.filesKey, action.file))
  }
}

function * updateFileSaga () {
  yield takeEvery(UPDATE_FILE, updateFilePerform)
}

export const filesSagas = [
  getFilesSaga,
  updateFileSaga
]

// Selectors

export const makeFilesLoadingSelector = (filesKey) => (state) => {
  return state.files[filesKey].loading
}

export const makeFilesLoadedSelector = (filesKey) => (state) => {
  return state.files[filesKey].loaded
}

export const makeFilesSelector = (filesKey) => (state) => {
  return state.files[filesKey].records
}

export const makeFilesForListSelector = (filesKey) => (state) => {
  const uploads = makeUploadsSelector(filesKey)(state)
  let files

  if (uploads.uploadedIds.length) {
    files = makeFilteredFilesSelector(filesKey)(state).map((file) => {
      if (uploads.uploadedIds.indexOf(file.id) === -1) {
        return file
      } else {
        return { ...file, attributes: { ...file.attributes, freshlyUploaded: true } }
      }
    })
  } else {
    files = makeFilteredFilesSelector(filesKey)(state)
  }

  return [
    ...Object.values(uploads.records).map((upload) => ({ ...upload, attributes: { ...upload.attributes, uploading: true } })),
    ...files
  ]
}

export const makeUnselectedFilesForListSelector = (filesKey) => (state) => {
  const all = makeFilesForListSelector(filesKey)(state)
  const selectedIds = makeSelectedFileIdsSelector(filesKey)(state)

  return filter(all, (file) => selectedIds.indexOf(file.id) === -1)
}

// State

const initialState = {
  images: {
    loading: false,
    loaded: false,
    records: []
  },
  documents: {
    loading: false,
    loaded: false,
    records: []
  }
}

// Reducer

function filesReducer (state = initialState, action) {
  switch (action.type) {
    case GET_FILES:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          loading: true
        }
      }

    case GET_FILES_SUCCESS:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: action.records,
          loading: false,
          loaded: true
        }
      }

    case UPLOADED_FILE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: [action.file, ...state[action.filesKey].records]
        }
      }

    case THUMBNAIL_GENERATED: {
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: state[action.filesKey].records.map((record) => {
            if (record.attributes.thumb !== action.temporaryUrl) return record
            return {
              ...record,
              attributes: {
                ...record.attributes,
                thumb: action.url
              }
            }
          })
        }
      }
    }

    case UPDATE_FILE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: state[action.filesKey].records.map((record) => {
            if (record.id === action.file.id) {
              return {
                ...record,
                attributes: {
                  ...record.attributes,
                  ...action.attributes,
                  updating: true
                }
              }
            } else {
              return record
            }
          })
        }
      }

    case UPDATE_FILE_SUCCESS:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: state[action.filesKey].records.map((record) => {
            if (record.id === action.response.id) {
              return action.response
            } else {
              return record
            }
          })
        }
      }

    case UPDATE_FILE_FAILURE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: state[action.filesKey].records.map((record) => {
            if (record.id === action.file.id) {
              return { ...action.file }
            } else {
              return record
            }
          })
        }
      }

    case UPDATED_FILES:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: state[action.filesKey].records.map((record) => {
            const found = find(action.files, { id: record.id })
            return found || record
          })
        }
      }

    default:
      return state
  }
}

export default filesReducer
