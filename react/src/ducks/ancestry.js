// Constants

const SET_ANCESTRY_DATA = 'ancestry/SET_ANCESTRY_DATA'
const UPDATE_ANCESTRY = 'ancestry/UPDATE_ANCESTRY'

// Actions

export function setAncestryData (data) {
  return { type: SET_ANCESTRY_DATA, data }
}

export function updateAncestry (items) {
  return { type: UPDATE_ANCESTRY, items }
}

// Selectors

export const ancestrySelector = (state) => state.ancestry

// State

const initialState = {
  items: [],
  maxNestingDepth: 1,
  hasInvalid: false
}

// Reducer

function ancestryReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ANCESTRY_DATA: {
      let hasInvalid = false
      const { items } = action.data
      const modify = (item) => {
        if (!item.valid) {
          hasInvalid = true
        }
        item.expanded = true
        item.children.forEach(modify)
      }
      items.forEach(modify)

      return {
        ...state,
        ...action.data,
        items,
        hasInvalid
      }
    }

    case UPDATE_ANCESTRY:
      return {
        ...state,
        items: action.items
      }

    default:
      return state
  }
}

export default ancestryReducer
