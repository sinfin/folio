// Constants

const SET_ORDERED_MULTISELECT_DATA = 'orderedMultiselect/SET_ORDERED_MULTISELECT_DATA'
const ADD_ITEM = 'orderedMultiselect/ADD_ITEM'
const UPDATE_ITEMS = 'orderedMultiselect/UPDATE_ITEMS'
const REMOVE_ITEM = 'orderedMultiselect/REMOVE_ITEM'

export const MENU_ITEM_URL = 'orderedMultiselect/MENU_ITEM_URL'

// Actions

export function setOrderedMultiselectData (data) {
  return { type: SET_ORDERED_MULTISELECT_DATA, data }
}

export function addItem () {
  return { type: ADD_ITEM }
}

export function updateItems (items) {
  return { type: UPDATE_ITEMS, items }
}

export function removeItem (items, removed) {
  return { type: REMOVE_ITEM, items, removed }
}

// Selectors

export const orderedMultiselectSelector = (state) => state.orderedMultiselect

// State

const initialState = {
  items: [],
  removedIds: [],
  paramBase: null,
  foreignKey: null,
  url: null
}

// Reducer

function orderedMultiselectReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ORDERED_MULTISELECT_DATA: {
      return {
        ...state,
        ...action.data
      }
    }

    case ADD_ITEM:
      return {
        ...state,
        items: [
          ...state.items
        ]
      }

    case REMOVE_ITEM: {
      const removedIds = state.removedIds
      const markRemoved = (item) => {
        if (item.id) removedIds.push(item.id)
        item.children.forEach(markRemoved)
      }
      markRemoved(action.removed)
      return {
        ...state,
        removedIds,
        items: action.items
      }
    }

    default:
      return state
  }
}

export default orderedMultiselectReducer
