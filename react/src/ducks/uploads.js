import { flashError } from 'utils/flash'
import { takeLatest, takeEvery, call, select, put } from 'redux-saga/effects'
import { omit, without } from 'lodash'

import { apiPost } from 'utils/api'
import { uploadedFile, updatedFiles } from 'ducks/files'
import { fileTypeSelector } from 'ducks/app'

// Constants

const ADDED_FILE = 'uploads/ADDED_FILE'
const THUMBNAIL = 'uploads/THUMBNAIL'
const SUCCESS = 'uploads/SUCCESS'
const ERROR = 'uploads/ERROR'
const FINISHED_UPLOAD = 'uploads/FINISHED_UPLOAD'
const PROGRESS = 'uploads/PROGRESS'
const SET_UPLOAD_TAGS = 'uploads/SET_UPLOAD_TAGS'
const CLEAR_UPLOADED_IDS = 'uploads/CLEAR_UPLOADED_IDS'

const idFromFile = (file) => {
  return [file.name, file.lastModified, file.size].join('|')
}

// Actions

export function addedFile (filesKey, file) {
  return { type: ADDED_FILE, filesKey, file }
}

export function thumbnail (filesKey, file, dataUrl) {
  return { type: THUMBNAIL, filesKey, file, dataUrl }
}

export function success (filesKey, file, response) {
  return { type: SUCCESS, filesKey, file, response }
}

export function finishedUpload (filesKey, file, uploadedFileId) {
  return { type: FINISHED_UPLOAD, filesKey, file, uploadedFileId }
}

export function error (filesKey, file, error) {
  return { type: ERROR, filesKey, file, error }
}

export function progress (filesKey, file, percentage) {
  return { type: PROGRESS, filesKey, file, percentage }
}

export function setUploadTags (filesKey, tags) {
  return { type: SET_UPLOAD_TAGS, filesKey, tags }
}

export function clearUploadedIds (filesKey, ids) {
  return { type: CLEAR_UPLOADED_IDS, filesKey, ids }
}

// Sagas

function * uploadsErrorPerform (action) {
  yield call(flashError, action.error)
}

function * uploadsErrorSaga () {
  yield takeLatest(ERROR, uploadsErrorPerform)
}

function * uploadedFilePerform (action) {
  const id = idFromFile(action.file)
  const upload = yield select(makeUploadSelector(action.filesKey)(id))
  const data = action.response.data
  yield put(finishedUpload(action.file, data.id))
  yield put(uploadedFile(action.filesKey, {
    ...data,
    attributes: {
      ...data.attributes,
      thumb: upload.thumb || data.attributes.thumb
    }
  }))
}

function * uploadedFileSaga () {
  yield takeLatest(SUCCESS, uploadedFilePerform)
}

function * setUploadTagsPerform (action) {
  const { uploadedIds, uploadTags } = yield select(makeUploadsSelector(action.filesKey))
  if (uploadedIds.length) {
    const fileType = yield select(fileTypeSelector)
    const url = fileType === 'Folio::Document' ? '/console/api/documents/tag' : '/console/api/images/tag'
    const response = yield call(apiPost, url, { file_ids: uploadedIds, tags: uploadTags })
    yield put(updatedFiles(action.filesKey, response.data))
    yield put(clearUploadedIds(action.filesKey, uploadedIds))
  }
}

function * setUploadTagsSaga () {
  yield takeEvery(SET_UPLOAD_TAGS, setUploadTagsPerform)
}

export const uploadsSagas = [
  uploadsErrorSaga,
  uploadedFileSaga,
  setUploadTagsSaga
]

// Selectors

export const makeUploadsSelector = (filesKey) => (state) => {
  return state.uploads[filesKey]
}

export const makeUploadSelector = (filesKey) => (id) => (state) => {
  return state.uploads[filesKey].records[id]
}

// State

const date = new Date()
export const defaultTag = `${date.getFullYear()}/${date.getMonth() + 1}`

const initialState = {
  images: {
    records: {},
    showTagger: false,
    uploadTags: [defaultTag],
    uploadedIds: []
  },
  documents: {
    records: {},
    showTagger: false,
    uploadTags: [defaultTag],
    uploadedIds: []
  }
}

// Reducer

function uploadsReducer (state = initialState, action) {
  const id = action.file ? idFromFile(action.file) : null

  switch (action.type) {
    case ADDED_FILE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: {
            ...state[action.filesKey].records,
            [id]: {
              id,
              attributes: {
                file: action.file,
                file_size: action.file.size,
                file_name: action.file.name,
                extension: action.file.type.split('/').pop().toUpperCase(),
                tags: state.uploadTags,
                thumb: null,
                progress: 0
              }
            }
          }
        }
      }

    case THUMBNAIL: {
      if (!state[action.filesKey].records[id]) return state

      return {
        ...state,
        [action.filesKey]: {
          records: {
            ...state[action.filesKey].records,
            [id]: {
              ...state[action.filesKey].records[id],
              attributes: {
                ...state[action.filesKey].records[id].attributes,
                thumb: action.dataUrl
              }
            }
          }
        }
      }
    }

    case PROGRESS:
      return {
        ...state,
        [action.filesKey]: {
          records: {
            ...state[action.filesKey].records,
            [id]: {
              ...state[action.filesKey].records[id],
              attributes: {
                ...state[action.filesKey].records[id].attributes,
                progress: action.percentage
              }
            }
          }
        }
      }

    case FINISHED_UPLOAD:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          showTagger: true,
          records: omit(state[action.filesKey].records, [id]),
          uploadedIds: [...state[action.filesKey].uploadedIds, action.uploadedFileId]
        }
      }

    case ERROR:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: omit(state[action.filesKey].records, [id])
        }
      }

    case SET_UPLOAD_TAGS:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          uploadTags: action.tags,
          showTagger: false
        }
      }

    case CLEAR_UPLOADED_IDS:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          uploadedIds: without(state[action.filesKey].uploadedIds, ...action.ids)
        }
      }

    default:
      return state
  }
}

export default uploadsReducer
