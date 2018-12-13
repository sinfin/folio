import { isEqual } from 'lodash'

import { filesSelector } from 'ducks/files'

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
