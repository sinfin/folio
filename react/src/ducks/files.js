import { apiGet, apiPut, apiDelete } from 'utils/api'
import { flashError, flashSuccess } from 'utils/flash'
import { takeLatest, takeEvery, call, put, select } from 'redux-saga/effects'
import { filter, find, without, omit } from 'lodash'

import { filesUrlSelector } from 'ducks/app'
import { makeUploadsSelector } from 'ducks/uploads'
import { makeFiltersQuerySelector } from 'ducks/filters'
import { makeSelectedFileIdsSelector } from 'ducks/filePlacements'

// Constants

const GET_FILES = 'files/GET_FILES'
const GET_FILES_SUCCESS = 'files/GET_FILES_SUCCESS'
const UPLOADED_FILE = 'files/UPLOADED_FILE'
const THUMBNAIL_GENERATED = 'files/THUMBNAIL_GENERATED'
const DELETE_FILE = 'files/DELETE_FILE'
const DELETE_FILE_FAILURE = 'files/DELETE_FILE_FAILURE'
const UPDATE_FILE = 'files/UPDATE_FILE'
export const UPDATE_FILE_SUCCESS = 'files/UPDATE_FILE_SUCCESS'
export const UPDATE_FILE_FAILURE = 'files/UPDATE_FILE_FAILURE'
const UPDATED_FILES = 'files/UPDATED_FILES'
const REMOVED_FILES = 'files/REMOVED_FILES'
const CHANGE_FILES_PAGE = 'files/CHANGE_FILES_PAGE'
const MASS_SELECT = 'files/MASS_SELECT'
const MASS_DELETE = 'files/MASS_DELETE'
const MASS_CANCEL = 'files/MASS_CANCEL'

// Actions

export function getFiles (fileType, filesUrl, query = '') {
  return { type: GET_FILES, fileType, filesUrl, query }
}

export function getFilesSuccess (fileType, records, meta) {
  return { type: GET_FILES_SUCCESS, fileType, records, meta }
}

export function uploadedFile (fileType, file) {
  return { type: UPLOADED_FILE, fileType, file }
}

export function thumbnailGenerated (fileType, temporaryUrl, url) {
  return { type: THUMBNAIL_GENERATED, fileType, temporaryUrl, url }
}

export function updatedFiles (fileType, files) {
  return { type: UPDATED_FILES, fileType, files }
}

export function updateFile (fileType, filesUrl, file, attributes) {
  return { type: UPDATE_FILE, fileType, filesUrl, file, attributes }
}

export function deleteFile (fileType, filesUrl, file) {
  return { type: DELETE_FILE, fileType, filesUrl, file }
}

export function deleteFileFailure (fileType, file) {
  return { type: DELETE_FILE_FAILURE, fileType, file }
}

export function removedFiles (fileType, ids) {
  return { type: REMOVED_FILES, fileType, ids }
}

export function updateFileSuccess (fileType, file, response) {
  return { type: UPDATE_FILE_SUCCESS, fileType, file, response }
}

export function updateFileFailure (fileType, file) {
  return { type: UPDATE_FILE_FAILURE, fileType, file }
}

export function changeFilesPage (fileType, filesUrl, page) {
  return { type: CHANGE_FILES_PAGE, fileType, filesUrl, page }
}

export function massSelect (fileType, file, select) {
  return { type: MASS_SELECT, fileType, file, select }
}

export function massDelete (fileType) {
  return { type: MASS_DELETE, fileType }
}

export function massCancel (fileType) {
  return { type: MASS_CANCEL, fileType }
}

// Sagas

function * getFilesPerform (action) {
  try {
    const filesUrl = `${action.filesUrl}?${action.query}`
    const response = yield call(apiGet, filesUrl)
    yield put(getFilesSuccess(action.fileType, response.data, response.meta))
  } catch (e) {
    flashError(e.message)
  }
}

function * getFilesSaga () {
  // takeLatest automatically cancels any saga task started previously if it's still running
  yield takeLatest(GET_FILES, getFilesPerform)
}

function * updateFilePerform (action) {
  try {
    const { file, filesUrl, attributes } = action
    const fullUrl = `${filesUrl}/${file.id}`
    const data = {
      file: {
        id: file.id,
        attributes
      }
    }
    const response = yield call(apiPut, fullUrl, data)
    yield put(updateFileSuccess(action.fileType, action.file, response.data))
  } catch (e) {
    flashError(e.message)
    yield put(updateFileFailure(action.fileType, action.file))
  }
}

function * updateFileSaga () {
  yield takeEvery(UPDATE_FILE, updateFilePerform)
}

function * changeFilesPagePerform (action) {
  try {
    const filtersQuery = yield select(makeFiltersQuerySelector(action.fileType))
    let query = `page=${action.page}`
    if (filtersQuery) {
      query = `${query}&${filtersQuery}`
    }
    yield put(getFiles(action.fileType, action.filesUrl, query))
  } catch (e) {
    flashError(e.message)
  }
}

function * changeFilesPageSaga () {
  yield takeLatest(CHANGE_FILES_PAGE, changeFilesPagePerform)
}

function * massDeletePerform (action) {
  try {
    const { massSelectedIds } = yield select(makeMassSelectedIdsSelector(action.fileType))
    const filesUrl = yield select(filesUrlSelector)
    const fullUrl = `${filesUrl}/mass_destroy?ids=${massSelectedIds.join(',')}`
    const res = yield call(apiDelete, fullUrl)
    if (res.error) {
      flashError(res.error)
    } else {
      flashSuccess(res.data.message)
      yield put(removedFiles(action.fileType, massSelectedIds))
      yield put(massCancel(action.fileType))
    }
  } catch (e) {
    flashError(e.message)
  }
}

function * massDeleteSaga () {
  yield takeLatest(MASS_DELETE, massDeletePerform)
}

function * deleteFilePerform (action) {
  try {
    const res = yield call(apiDelete, `${action.filesUrl}/${action.file.id}`)
    if (res.error) {
      flashError(res.error)
    } else {
      yield put(removedFiles(action.fileType, [action.file.id]))
    }
  } catch (e) {
    flashError(e.message)
  }
}

function * deleteFileSaga () {
  yield takeLatest(DELETE_FILE, deleteFilePerform)
}

export const filesSagas = [
  getFilesSaga,
  updateFileSaga,
  changeFilesPageSaga,
  massDeleteSaga,
  deleteFileSaga
]

// Selectors

export const makeFilesStatusSelector = (fileType) => (state) => {
  return {
    loading: state.files[fileType] && state.files[fileType].loading,
    loaded: state.files[fileType] && state.files[fileType].loaded,
    massSelecting: state.files[fileType].massSelectedIds.length > 0
  }
}

export const makeFilesLoadedSelector = (fileType) => (state) => {
  return state.files[fileType] && state.files[fileType].loaded
}

export const makeMassSelectedIdsSelector = (fileType) => (state) => {
  const base = state.files[fileType] || defaultFilesKeyState
  return {
    massSelectedIds: base.massSelectedIds,
    massSelectedIndestructibleIds: base.massSelectedIndestructibleIds
  }
}

export const makeFilesSelector = (fileType) => (state) => {
  const base = state.files[fileType] || defaultFilesKeyState
  const selected = base.massSelectedIds
  return base.records.map((file) => {
    if (file.id && selected.indexOf(file.id) !== -1) {
      return { ...file, massSelected: true }
    } else {
      return file
    }
  })
}

export const makeFilesForListSelector = (fileType) => (state) => {
  const uploads = makeUploadsSelector(fileType)(state)
  let files

  if (uploads.uploadedIds.length) {
    files = makeFilesSelector(fileType)(state).map((file) => {
      if (uploads.uploadedIds.indexOf(file.id) === -1) {
        return file
      } else {
        return { ...file, attributes: { ...file.attributes, freshlyUploaded: true } }
      }
    })
  } else {
    files = makeFilesSelector(fileType)(state)
  }

  return [
    ...Object.values(uploads.records).map((upload) => ({ ...upload, attributes: { ...upload.attributes, uploading: true } })),
    ...files
  ]
}

export const makeRawUnselectedFilesForListSelector = (fileType, selectedIds) => (state) => {
  const all = makeFilesForListSelector(fileType)(state)
  return filter(all, (file) => selectedIds.indexOf(String(file.id)) === -1)
}

export const makeUnselectedFilesForListSelector = (fileType) => (state) => {
  const all = makeFilesForListSelector(fileType)(state)
  const selectedIds = makeSelectedFileIdsSelector(fileType)(state)

  return filter(all, (file) => selectedIds.indexOf(String(file.id)) === -1)
}

export const makeFilesPaginationSelector = (fileType) => (state) => {
  const base = state.files[fileType] || defaultFilesKeyState
  return base.pagination
}

export const makeFilesReactTypeSelector = (fileType) => (state) => {
  const base = state.files[fileType] || defaultFilesKeyState
  return base.reactType
}

export const makeFilesReactTypeIsImageSelector = (fileType) => (state) => {
  return makeFilesReactTypeSelector(fileType)(state) === 'image'
}

// State

const defaultFilesKeyState = {
  loading: false,
  loaded: false,
  records: [],
  massSelectedIds: [],
  massSelectedIndestructibleIds: [],
  reactType: 'document',
  pagination: {
    page: null,
    pages: null
  }
}

const initialState = {}

// Reducer

function filesReducer (rawState = initialState, action) {
  const state = rawState

  if (action.fileType && !state[action.fileType]) {
    state[action.fileType] = { ...defaultFilesKeyState }
  }

  switch (action.type) {
    case GET_FILES:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          loading: true
        }
      }

    case GET_FILES_SUCCESS:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: action.records,
          loading: false,
          loaded: true,
          pagination: omit(action.meta, ['react_type']),
          reactType: action.meta.react_type
        }
      }

    case UPLOADED_FILE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: [action.file, ...state[action.fileType].records]
        }
      }

    case THUMBNAIL_GENERATED: {
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: state[action.fileType].records.map((record) => {
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
        [action.fileType]: {
          ...state[action.fileType],
          records: state[action.fileType].records.map((record) => {
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
        [action.fileType]: {
          ...state[action.fileType],
          records: state[action.fileType].records.map((record) => {
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
        [action.fileType]: {
          ...state[action.fileType],
          records: state[action.fileType].records.map((record) => {
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
        [action.fileType]: {
          ...state[action.fileType],
          records: state[action.fileType].records.map((record) => {
            const found = find(action.files, { id: record.id })
            return found || record
          })
        }
      }

    case MASS_SELECT: {
      if (!action.file.id) return state

      let massSelectedIds = state[action.fileType].massSelectedIds
      let massSelectedIndestructibleIds = state[action.fileType].massSelectedIndestructibleIds

      if (action.select) {
        massSelectedIds = [...massSelectedIds, action.file.id]

        if (action.file.attributes.file_placements_size) {
          massSelectedIndestructibleIds = [...massSelectedIndestructibleIds, action.file.id]
        }
      } else {
        massSelectedIds = without(massSelectedIds, action.file.id)

        if (action.file.attributes.file_placements_size) {
          massSelectedIndestructibleIds = without(massSelectedIndestructibleIds, action.file.id)
        }
      }

      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          massSelectedIds,
          massSelectedIndestructibleIds
        }
      }
    }

    case MASS_CANCEL:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          massSelectedIds: []
        }
      }

    case REMOVED_FILES: {
      const originalLength = state[action.fileType].records.length
      const records = state[action.fileType].records.filter((record) => action.ids.indexOf(record.id) === -1)
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records,
          pagination: {
            ...state[action.fileType].pagination,
            to: records.length,
            count: state[action.fileType].pagination.count - (originalLength - records.length)
          }
        }
      }
    }

    case DELETE_FILE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: state[action.fileType].records.map((record) => {
            if (record.id === action.file.id) {
              return {
                ...record,
                _destroying: true
              }
            } else {
              return record
            }
          })
        }
      }

    case DELETE_FILE_FAILURE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          records: state[action.fileType].records.map((record) => {
            if (record.id === action.file.id) {
              return { ...action.file }
            } else {
              return record
            }
          })
        }
      }

    default:
      return state
  }
}

export default filesReducer
