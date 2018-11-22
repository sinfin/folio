import { flashError } from 'utils/flash'
import { takeLatest, call, select, put } from 'redux-saga/effects'
import { omit } from 'lodash'

import { uploadedFile } from 'ducks/files'

// Constants

const ADDED_FILE = 'uploads/ADDED_FILE'
const THUMBNAIL = 'uploads/THUMBNAIL'
const SUCCESS = 'uploads/SUCCESS'
const ERROR = 'uploads/ERROR'
const REMOVE = 'uploads/REMOVE'
const PROGRESS = 'uploads/PROGRESS'

const idFromFile = (file) => [file.name, file.lastModified].join('-=-')

// Actions

export function addedFile (file) {
  return { type: ADDED_FILE, file }
}

export function thumbnail (file, dataUrl) {
  return { type: THUMBNAIL, file, dataUrl }
}

export function success (file, response) {
  return { type: SUCCESS, file, response }
}

export function remove (file) {
  return { type: REMOVE, file }
}

export function error (file, error) {
  return { type: ERROR, file, error }
}

export function progress (file, percentage) {
  return { type: PROGRESS, file, percentage }
}

// Sagas

function * uploadsErrorPerform (action) {
  yield call(flashError, action.error)
}

function * uploadsErrorSaga (): Generator<*, *, *> {
  yield takeLatest(ERROR, uploadsErrorPerform)
}

function * uploadedFilePerform (action) {
  const id = idFromFile(action.file)
  const upload = yield select(uploadSelector(id))
  yield put(remove(action.file))
  yield put(uploadedFile({
    ...action.response,
    thumb: upload.thumb,
  }))
}

function * uploadedFileSaga (): Generator<*, *, *> {
  yield takeLatest(SUCCESS, uploadedFilePerform)
}

export const uploadsSagas = [
  uploadsErrorSaga,
  uploadedFileSaga,
]

// Selectors

export const uploadsSelector = (state) => {
  const base = state.uploads
  return {
    ...base,
    records: Object.values(base.records),
  }
}

export const uploadSelector = (id) => (state) => {
  const base = state.uploads
  return base.records[id]
}

export const uploadTypeSelector = (state) => {
  const base = state.uploads
  return base.type
}

// State

const initialState = {
  records: {},
}

// Reducer

function uploadsReducer (state = initialState, action) {
  const id = action.file ? idFromFile(action.file) : null

  switch (action.type) {
    case ADDED_FILE:
      return {
        ...state,
        records: {
          ...state.records,
          [id]: {
            id,
            file: action.file,
            file_size: action.file.size,
            file_name: action.file.name,
            extension: action.file.type.split('/').pop().toUpperCase(),
            tags: [],
            thumb: null,
            progress: 0,
          },
        }
      }

    case THUMBNAIL:
      return {
        ...state,
        records: {
          ...state.records,
          [id]: {
            ...state.records[id],
            thumb: action.dataUrl,
          },
        }
      }

    case PROGRESS:
      return {
        ...state,
        records: {
          ...state.records,
          [id]: {
            ...state.records[id],
            progress: action.percentage,
          },
        }
      }

    case REMOVE:
    case ERROR: {
      return {
        ...state,
        records: omit(state.records, [id]),
      }
    }

    default:
      return state
  }
}

export default uploadsReducer
