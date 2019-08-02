import { isEqual } from 'lodash'

import { makeFilesSelector } from 'ducks/files'

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

// Selectors

export const makeFiltersSelector = (filesKey) => (state) => {
  const filters = state.filters[filesKey]
  const active = !isEqual(filters, initialState[filesKey])

  return {
    ...filters,
    active
  }
}

export const makeFilteredFilesSelector = (filesKey) => (state) => {
  const files = makeFilesSelector(filesKey)(state)
  const filters = makeFiltersSelector(filesKey)(state)
  const filtered = []

  files.forEach((file) => {
    let valid = true

    if (valid && filters.name) {
      valid = new RegExp(filters.name, 'i').test(file.attributes.file_name)
    }

    if (valid && filters.tags.length) {
      if (file.attributes.tags.length) {
        filters.tags.forEach((tag) => {
          valid = valid && file.attributes.tags.indexOf(tag) !== -1
        })
      } else {
        valid = false
      }
    }

    if (valid && filters.placement) {
      valid = file.attributes.placements.indexOf(filters.placement) !== -1
    }

    if (valid) filtered.push(file)
  })

  return filtered
}

export const makeTagsSelector = (filesKey) => (state) => {
  const files = makeFilesSelector(filesKey)(state)
  const tags = []
  files.forEach((file) => file.attributes.tags.forEach((tag) => {
    if (tags.indexOf(tag) === -1) tags.push(tag)
  }))
  return tags.sort((a, b) => {
    const lowerA = a.toLowerCase()
    const lowerB = b.toLowerCase()
    return lowerA > lowerB ? 1 : lowerB > lowerA ? -1 : 0
  })
}

export const makePlacementsSelector = (filesKey) => (state) => {
  const files = makeFilesSelector(filesKey)(state)
  const placements = []
  files.forEach((file) => file.attributes.placements.forEach((placement) => {
    if (placements.indexOf(placement) === -1) placements.push(placement)
  }))
  return placements
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
