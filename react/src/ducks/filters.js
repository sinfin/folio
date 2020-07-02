import { isEqual, omit } from 'lodash'
import { delay } from 'redux-saga'
import { takeLatest, put, select } from 'redux-saga/effects'

import { flashError } from 'utils/flash'
import { getFiles } from 'ducks/files'

// Constants

const SET_FILTER = 'filters/SET_FILTER'
const RESET_FILTERS = 'filters/RESET_FILTERS'

// Actions

export function setFilter (fileType, filesUrl, filter, value) {
  return { type: SET_FILTER, fileType, filesUrl, filter, value }
}

export function unsetFilter (fileType, filesUrl, filter) {
  return setFilter(fileType, filesUrl, filter, filter === 'tags' ? [] : '')
}

export function resetFilters (fileType, filesUrl) {
  return { type: RESET_FILTERS, fileType, filesUrl }
}

// Sagas

function * updateFiltersPerform (action) {
  try {
    // debounce by 750ms, using delay with takeLatest
    let query = ''
    if (action.type === SET_FILTER) {
      yield delay(750)
      query = yield select(makeFiltersQuerySelector(action.fileType))
    }
    yield put(getFiles(action.fileType, action.filesUrl, query))
  } catch (e) {
    flashError(e.message)
  }
}

function * updateFiltersSaga () {
  yield [
    takeLatest(SET_FILTER, updateFiltersPerform),
    takeLatest(RESET_FILTERS, updateFiltersPerform)
  ]
}

export const filtersSagas = [
  updateFiltersSaga
]

// Selectors

export const makeFiltersSelector = (fileType) => (state) => {
  const base = state.filters[fileType] || defaultFiltersKeysState
  const active = !isEqual(base, defaultFiltersKeysState)

  return {
    ...base,
    active
  }
}

export const makeFiltersQuerySelector = (fileType) => (state) => {
  const base = state.filters[fileType] || defaultFiltersKeysState
  const params = new URLSearchParams()

  Object.keys(base).forEach((key) => {
    let value = base[key]
    if (key === 'tags') {
      value = base[key].join(',')
    }
    if (value) {
      params.set(`by_${key}`, value)
    }
  })

  return params.toString()
}

export const makePlacementsSelector = (fileType) => (state) => {
  // return window.FolioConsole.ReactMetaData.placements
  return []
}

// State

const defaultFiltersKeysState = {
  file_name: '',
  tags: [],
  placement: ''
}

export const initialState = {}

// Reducer

function filtersReducer (rawState = initialState, action) {
  const state = rawState

  if (action.fileType && !state[action.fileType]) {
    state[action.fileType] = { ...defaultFiltersKeysState }
  }

  switch (action.type) {
    case SET_FILTER: {
      const obj = omit(state[action.fileType], [action.filter])

      if (action.value) {
        obj[action.filter] = action.value
      }

      return {
        ...state,
        [action.fileType]: obj
      }
    }

    case RESET_FILTERS:
      return initialState

    default:
      return state
  }
}

export default filtersReducer
