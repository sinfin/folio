import { uniqueId } from 'lodash'

// Constants

const SET_MENUS_DATA = 'menus/SET_MENUS_DATA'
const UPDATE_ITEMS = 'menus/UPDATE_ITEMS'

// Actions

export function setMenusData (data) {
  return { type: SET_MENUS_DATA, data }
}

export function updateItems (items) {
  return { type: UPDATE_ITEMS, items }
}

// Selectors

export const menusSelector = (state) => state.menus

// State

const initialState = {
  paths: {},
  items: [],
  maxNestingDepth: 1
}

// Reducer

function menusReducer (state = initialState, action) {
  switch (action.type) {
    case SET_MENUS_DATA: {
      const { items } = action.data
      const modify = (item) => {
        item.expanded = true
        item.uniqueId = uniqueId()
        item.children.forEach(modify)
      }
      items.forEach(modify)

      return {
        ...state,
        ...action.data,
        items
      }
    }

    case UPDATE_ITEMS:
      return {
        ...state,
        items: action.items
      }

    default:
      return state
  }
}

export default menusReducer
