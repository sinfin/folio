import { isEqual } from 'lodash'
import { delay } from 'redux-saga'
import { takeLatest, put, select } from 'redux-saga/effects'

import { flashError } from 'utils/flash'
import { makeFilesSelector, getFiles } from 'ducks/files'

// Constants

const SET_FILTER = 'filters/SET_FILTER'
const RESET_FILTERS = 'filters/RESET_FILTERS'

// Actions

export function setFilter (filesKey, filter, value) {
  return { type: SET_FILTER, filesKey, filter, value }
}

export function unsetFilter (filesKey, filter) {
  return setFilter(filesKey, filter, filter === 'tags' ? [] : '')
}

export function resetFilters (filesKey) {
  return { type: RESET_FILTERS, filesKey }
}

// Sagas

function * setFilterPerform (action) {
  try {
    // debounce by 750ms, using delay with takeLatest
    yield delay(750)
    const query = yield select(makeFiltersQuerySelector(action.filesKey))
    yield put(getFiles(action.filesKey, query))
  } catch (e) {
    flashError(e.message)
  }
}

function * setFilterSaga () {
  yield takeLatest(SET_FILTER, setFilterPerform)
}

export const filtersSagas = [
  setFilterSaga
]

// Selectors

export const makeFiltersSelector = (filesKey) => (state) => {
  const filters = state.filters[filesKey]
  const active = !isEqual(filters, initialState[filesKey])

  return {
    ...filters,
    active
  }
}

export const makeTagsSelector = (filesKey) => (state) => {
  const tags = window.FolioConsole.ReactMetaData.tags

  const files = makeFilesSelector(filesKey)(state)
  files.forEach((file) => file.attributes.tags.forEach((tag) => {
    if (tags.indexOf(tag) === -1) tags.push(tag)
  }))
  return tags
}

export const makeFiltersQuerySelector = (filesKey) => (state) => {
  const filters = state.filters[filesKey]
  const params = new URLSearchParams()
  Object.keys(filters).forEach((key) => {
    let value = filters[key]
    if (key === 'tags') {
      value = filters[key].join(',')
    }
    if (value) {
      params.set(`by_${key}`, value)
    }
  })
  return params.toString()
}

export const makePlacementsSelector = (filesKey) => (state) => {
  // return window.FolioConsole.ReactMetaData.placements
  return []
}

// State

export const initialState = {
  documents: {
    name: '',
    tags: [],
    placement: null
  },
  images: {
    name: '',
    tags: [],
    placement: null
  }
}

// Reducer

function filtersReducer (state = initialState, action) {
  switch (action.type) {
    case SET_FILTER:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          [action.filter]: action.value
        }
      }

    case RESET_FILTERS:
      return initialState

    default:
      return state
  }
}

export default filtersReducer
