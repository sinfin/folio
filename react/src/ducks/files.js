import { apiGet, apiPut, apiDelete } from 'utils/api'
import { flashError, flashSuccess } from 'utils/flash'
import { takeLatest, takeEvery, call, put, select } from 'redux-saga/effects'
import { filter, find, without } from 'lodash'

import { fileTypeSelector } from 'ducks/app'
import { makeUploadsSelector } from 'ducks/uploads'
import { makeFiltersQuerySelector } from 'ducks/filters'
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
const REMOVED_FILES = 'files/REMOVED_FILES'
const CHANGE_FILES_PAGE = 'files/CHANGE_FILES_PAGE'
const MASS_SELECT = 'files/MASS_SELECT'
const MASS_DELETE = 'files/MASS_DELETE'
const MASS_CANCEL = 'files/MASS_CANCEL'

// Actions

export function getFiles (filesKey, query = '') {
  return { type: GET_FILES, filesKey, query }
}

export function getFilesSuccess (filesKey, records, pagination) {
  return { type: GET_FILES_SUCCESS, filesKey, records, pagination }
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

export function removedFiles (filesKey, ids) {
  return { type: REMOVED_FILES, filesKey, ids }
}

export function updateFileSuccess (filesKey, file, response) {
  return { type: UPDATE_FILE_SUCCESS, filesKey, file, response }
}

export function updateFileFailure (filesKey, file) {
  return { type: UPDATE_FILE_FAILURE, filesKey, file }
}

export function changeFilesPage (filesKey, page) {
  return { type: CHANGE_FILES_PAGE, filesKey, page }
}

export function massSelect (filesKey, file, select) {
  return { type: MASS_SELECT, filesKey, file, select }
}

export function massDelete (filesKey) {
  return { type: MASS_DELETE, filesKey }
}

export function massCancel (filesKey) {
  return { type: MASS_CANCEL, filesKey }
}

// Sagas

function * getFilesPerform (action) {
  try {
    const filesUrl = `/console/api/${action.filesKey}?${action.query}`
    const records = yield call(apiGet, filesUrl)
    yield put(getFilesSuccess(action.filesKey, records.data, records.meta))
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

function * changeFilesPagePerform (action) {
  try {
    const filtersQuery = yield select(makeFiltersQuerySelector(action.filesKey))
    let query = `page=${action.page}`
    if (filtersQuery) {
      query = `${query}&${filtersQuery}`
    }
    yield put(getFiles(action.filesKey, query))
  } catch (e) {
    flashError(e.message)
  }
}

function * changeFilesPageSaga () {
  yield takeLatest(CHANGE_FILES_PAGE, changeFilesPagePerform)
}

function * massDeletePerform (action) {
  try {
    const { massSelectedIds } = yield select(makeMassSelectedIdsSelector(action.filesKey))
    const res = yield call(apiDelete, `/console/api/${action.filesKey}/mass_destroy?ids=${massSelectedIds.join(',')}`)
    if (res.error) {
      flashError(res.error)
    } else {
      flashSuccess(res.data.message)
      yield put(removedFiles(action.filesKey, massSelectedIds))
      yield put(massCancel(action.filesKey))
    }
  } catch (e) {
    flashError(e.message)
  }
}

function * massDeleteSaga () {
  yield takeLatest(MASS_DELETE, massDeletePerform)
}

export const filesSagas = [
  getFilesSaga,
  updateFileSaga,
  changeFilesPageSaga,
  massDeleteSaga
]

// Selectors

export const makeFilesStatusSelector = (filesKey) => (state) => {
  return {
    loading: state.files[filesKey] && state.files[filesKey].loading,
    loaded: state.files[filesKey] && state.files[filesKey].loaded,
    massSelecting: state.files[filesKey].massSelectedIds.length > 0
  }
}

export const makeFilesLoadedSelector = (filesKey) => (state) => {
  return state.files[filesKey] && state.files[filesKey].loaded
}

export const makeMassSelectedIdsSelector = (filesKey) => (state) => {
  return {
    massSelectedIds: state.files[filesKey].massSelectedIds,
    massSelectedIndestructibleIds: state.files[filesKey].massSelectedIndestructibleIds
  }
}

export const makeFilesSelector = (filesKey) => (state) => {
  const selected = state.files[filesKey].massSelectedIds
  return state.files[filesKey].records.map((file) => {
    if (file.id && selected.indexOf(file.id) !== -1) {
      return { ...file, massSelected: true }
    } else {
      return file
    }
  })
}

export const makeFilesForListSelector = (filesKey) => (state) => {
  const uploads = makeUploadsSelector(filesKey)(state)
  let files

  if (uploads.uploadedIds.length) {
    files = makeFilesSelector(filesKey)(state).map((file) => {
      if (uploads.uploadedIds.indexOf(file.id) === -1) {
        return file
      } else {
        return { ...file, attributes: { ...file.attributes, freshlyUploaded: true } }
      }
    })
  } else {
    files = makeFilesSelector(filesKey)(state)
  }

  return [
    ...Object.values(uploads.records).map((upload) => ({ ...upload, attributes: { ...upload.attributes, uploading: true } })),
    ...files
  ]
}

export const makeRawUnselectedFilesForListSelector = (filesKey, selectedIds) => (state) => {
  const all = makeFilesForListSelector(filesKey)(state)
  return filter(all, (file) => selectedIds.indexOf(String(file.id)) === -1)
}

export const makeUnselectedFilesForListSelector = (filesKey) => (state) => {
  const all = makeFilesForListSelector(filesKey)(state)
  const selectedIds = makeSelectedFileIdsSelector(filesKey)(state)

  return filter(all, (file) => selectedIds.indexOf(String(file.id)) === -1)
}

export const makeFilesPaginationSelector = (filesKey) => (state) => {
  return state.files[filesKey].pagination
}

// State

const initialState = {
  images: {
    loading: false,
    loaded: false,
    records: [],
    massSelectedIds: [],
    massSelectedIndestructibleIds: [],
    pagination: {
      page: null,
      pages: null
    }
  },
  documents: {
    loading: false,
    loaded: false,
    records: [],
    massSelectedIds: [],
    massSelectedIndestructibleIds: [],
    pagination: {
      page: null,
      pages: null
    }
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
          loaded: true,
          pagination: action.pagination
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

    case MASS_SELECT: {
      if (!action.file.id) return state

      let massSelectedIds = state[action.filesKey].massSelectedIds
      let massSelectedIndestructibleIds = state[action.filesKey].massSelectedIndestructibleIds

      if (action.select) {
        massSelectedIds = [...massSelectedIds, action.file.id]

        if (action.file.attributes.file_placements_count) {
          massSelectedIndestructibleIds = [...massSelectedIndestructibleIds, action.file.id]
        }
      } else {
        massSelectedIds = without(massSelectedIds, action.file.id)

        if (action.file.attributes.file_placements_count) {
          massSelectedIndestructibleIds = without(massSelectedIndestructibleIds, action.file.id)
        }
      }

      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          massSelectedIds,
          massSelectedIndestructibleIds
        }
      }
    }

    case MASS_CANCEL:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          massSelectedIds: []
        }
      }

    case REMOVED_FILES:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          records: state[action.filesKey].records.filter((record) => action.ids.indexOf(record.id) === -1)
        }
      }

    default:
      return state
  }
}

export default filesReducer
