import { apiGet, apiPut } from 'utils/api'
import { flashError } from 'utils/flash'
import { takeLatest, takeEvery, call, put, select } from 'redux-saga/effects'
import { filter, find } from 'lodash'

import { fileTypeSelector } from 'ducks/app'
import { filteredFilesSelector } from 'ducks/filters'
import { uploadsSelector } from 'ducks/uploads'
import { selectedFileIdsSelector } from 'ducks/filePlacements'

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

export function getFiles () {
  return { type: GET_FILES }
}

export function getFilesSuccess (records) {
  return { type: GET_FILES_SUCCESS, records }
}

export function uploadedFile (file) {
  return { type: UPLOADED_FILE, file }
}

export function thumbnailGenerated (temporary_url, url) {
  return { type: THUMBNAIL_GENERATED, temporary_url, url }
}

export function updatedFiles (files) {
  return { type: UPDATED_FILES, files }
}

export function updateFile (file, attributes) {
  return { type: UPDATE_FILE, file, attributes }
}

export function updateFileSuccess (file, response) {
  return { type: UPDATE_FILE_SUCCESS, file, response }
}

export function updateFileFailure (file) {
  return { type: UPDATE_FILE_FAILURE, file }
}

// Sagas

function * getFilesPerform (action) {
  try {
    const fileType = yield select(fileTypeSelector)
    const filesUrl = fileType === 'Folio::Document' ? '/console/documents.json' : '/console/images.json'
    const records = yield call(apiGet, filesUrl)
    yield put(getFilesSuccess(records))
  } catch (e) {
    flashError(e.message)
  }
}

function * getFilesSaga (): Generator<*, *, *> {
  yield takeLatest(GET_FILES, getFilesPerform)
}

function * updateFilePerform (action) {
  try {
    const { file, attributes } = action
    const fileType = yield select(fileTypeSelector)
    const fileUrl = fileType === 'Folio::Document' ? `/console/documents/${file.id}.json` : `/console/images/${file.id}.json`
    const response = yield call(apiPut, fileUrl, { file: attributes })
    yield put(updateFileSuccess(action.file, response.file))
  } catch (e) {
    flashError(e.message)
    yield put(updateFileFailure(action.file))
  }
}

function * updateFileSaga (): Generator<*, *, *> {
  yield takeEvery(UPDATE_FILE, updateFilePerform)
}

export const filesSagas = [
  getFilesSaga,
  updateFileSaga,
]

// Selectors

export const filesLoadingSelector = (state) => {
  return state.files.loading
}

export const filesLoadedSelector = (state) => {
  return state.files.loaded
}

export const filesSelector = (state) => {
  return state.files.records
}

export const filesForListSelector = (state) => {
  const uploads = uploadsSelector(state)
  let files

  if (uploads.uploadedIds.length) {
    files = filteredFilesSelector(state).map((file) => {
      if (uploads.uploadedIds.indexOf(file.id) === -1) {
        return file
      } else {
        return { ...file, freshlyUploaded: true }
      }
    })
  } else {
    files = filteredFilesSelector(state)
  }

  return [
    ...Object.values(uploads.records).map((upload) => ({ ...upload, uploading: true })),
    ...files,
  ]
}

export const unselectedFilesForListSelector = (state) => {
  const all = filesForListSelector(state)
  const selectedIds = selectedFileIdsSelector(state)

  return filter(all, (file) => selectedIds.indexOf(file.id) === -1)
}

// State

const initialState = {
  loading: false,
  loaded: false,
  filesUrl: '/console/files.json',
  records: [],
}

// Reducer

function filesReducer (state = initialState, action) {
  switch (action.type) {
    case GET_FILES:
      return {
        ...state,
        loading: true,
      }

    case GET_FILES_SUCCESS:
      return {
        ...state,
        records: action.records,
        loading: false,
        loaded: true,
      }

    case UPLOADED_FILE:
      return {
        ...state,
        records: [action.file, ...state.records]
      }

    case THUMBNAIL_GENERATED: {
      return {
        ...state,
        records: state.records.map((record) => {
          if (record.thumb !== action.temporary_url) return record
          return {
            ...record,
            thumb: action.url,
          }
        }),
      }
    }

    case UPDATE_FILE:
      return {
        ...state,
        records: state.records.map((record) => {
          if (record.id === action.file.id) {
            return {
              ...record,
              ...action.attributes,
              updating: true,
            }
          } else {
            return record
          }
        }),
      }

    case UPDATE_FILE_SUCCESS:
      return {
        ...state,
        records: state.records.map((record) => {
          if (record.id === action.response.id) {
            return action.response
          } else {
            return record
          }
        }),
      }

    case UPDATE_FILE_FAILURE:
      return {
        ...state,
        records: state.records.map((record) => {
          if (record.id === action.file.id) {
            return record
          } else {
            return { ...action.file }
          }
        }),
      }

    case UPDATED_FILES:
      return {
        ...state,
        records: state.records.map((record) => {
          const found = find(action.files, { id: record.id })
          return found || record
        }),
      }

    default:
      return state
  }
}

export default filesReducer
