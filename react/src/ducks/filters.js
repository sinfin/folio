import { fromJS } from 'immutable'

import { filesSelector } from 'ducks/files'

// Constants

const SET_FILTER = 'filters/SET_FILTER'

// Actions

export function setFilter (filter, value) {
  return { type: SET_FILTER, filter, value }
}

export function unsetFilter (filter) {
  return setFilter(filter, '')
}

// Selectors

export const filtersSelector = (state) => {
  return state.get('filters').toJS()
}

export const filteredFilesSelector = (state) => {
  const files = filesSelector(state)
  const filters = filtersSelector(state)
  let selectable = []

  files.selectable.forEach((file) => {
    let valid = true
    if (filters.name) {
      valid = new RegExp(filters.name, 'i').test(file.file_name)
    }
    if (valid) selectable.push(file)
  })

  return {
    ...files,
    selectable,
  }
}

// State

const initialState = fromJS({
  name: '',
})

// Reducer

function filtersReducer (state = initialState, action) {
  switch (action.type) {
    case SET_FILTER:
      return state.set(action.filter, action.value)

    default:
      return state
  }
}

export default filtersReducer
