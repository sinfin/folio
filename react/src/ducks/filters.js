import { isEqual } from 'lodash'

import {
  allFilesSelector,
  filesSelector,
} from 'ducks/files'

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
  let selectable = []

  files.selectable.forEach((file) => {
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

    if (valid) selectable.push(file)
  })

  return {
    ...files,
    selectable,
  }
}

export const tagsSelector = (state) => {
  const files = allFilesSelector(state)
  let tags = []
  files.forEach((file) => file.tags.forEach((tag) => {
    if (tags.indexOf(tag) === -1) tags.push(tag)
  }))
  return tags
}

// State

const initialState = {
  name: '',
  tags: [],
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
