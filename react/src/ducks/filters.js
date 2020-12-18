import { isEqual } from 'lodash'
import { delay } from 'redux-saga'
import { takeLatest, put, select } from 'redux-saga/effects'

import { flashError } from 'utils/flash'
import { filesSelector, getFiles } from 'ducks/files'

// Constants

const SET_FILTER = 'filters/SET_FILTER'
const RESET_FILTERS = 'filters/RESET_FILTERS'

// Actions

export function setFilter (filter, value) {
  return { type: SET_FILTER, filter, value }
}

export function unsetFilter (filter) {
  return setFilter(filter, '')
}

export function resetFilters () {
  return { type: RESET_FILTERS }
}

// Sagas

function * updateFiltersPerform (action) {
  try {
    // debounce by 750ms, using delay with takeLatest
    let query = ''
    if (action.type === SET_FILTER) {
      yield delay(750)
      query = yield select(filtersQuerySelector)
    }
    yield put(getFiles(query))
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

export const filtersSelector = (state) => {
  const filters = state.filters
  const active = !isEqual(filters, initialState)

  return {
    ...filters,
    active,
  }
}

export const filteredFilesSelector = (state) => {
  const files = filesSelector(state)
  const filters = filtersSelector(state)
  let filtered = []

  files.forEach((file) => {
    let valid = true

    if (valid && filters.name) {
      valid = new RegExp(filters.name, 'i').test(file.file_name)
    }

    if (valid && filters.tags.length) {
      if (file.tags.length) {
        filters.tags.forEach((tag) => {
          valid = valid && file.tags.indexOf(tag) !== -1
        })
      } else {
        valid = false
      }
    }

    if (valid && filters.placement) {
      valid = file.placements.indexOf(filters.placement) !== -1
    }

    if (valid) filtered.push(file)
  })

  return filtered
}

export const tagsSelector = (state) => {
  const files = filesSelector(state)
  let tags = []
  files.forEach((file) => file.tags.forEach((tag) => {
    if (tags.indexOf(tag) === -1) tags.push(tag)
  }))
  return tags.sort((a, b) => {
    const lowerA = a.toLowerCase()
    const lowerB = b.toLowerCase()
    return lowerA > lowerB ? 1 : lowerB > lowerA ? -1 : 0;
  })
}

export const placementsSelector = (state) => {
  const files = filesSelector(state)
  let placements = []
  files.forEach((file) => file.placements.forEach((placement) => {
    if (placements.indexOf(placement) === -1) placements.push(placement)
  }))
  return placements
}

export const filtersQuerySelector = (state) => {
  const base = state.filters
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

// State

const initialState = {
  name: '',
  tags: [],
  placement: null,
}

// Reducer

function filtersReducer (state = initialState, action) {
  switch (action.type) {
    case SET_FILTER:
      return {
        ...state,
        [action.filter]: action.value,
      }

    case RESET_FILTERS:
      return initialState

    default:
      return state
  }
}

export default filtersReducer
