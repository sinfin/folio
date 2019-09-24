import { uniqueId } from 'lodash'

// Constants

const SET_MENUS_DATA = 'menus/SET_MENUS_DATA'
const ADD_ITEM = 'menus/ADD_ITEM'
const UPDATE_ITEMS = 'menus/UPDATE_ITEMS'
const REMOVE_ITEM = 'menus/REMOVE_ITEM'

// Actions

export function setMenusData (data) {
  return { type: SET_MENUS_DATA, data }
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

export const menusSelector = (state) => state.menus

// State

const initialState = {
  paths: {},
  items: [],
  maxNestingDepth: 1,
  removedIds: []
}

const makeItem = () => ({
  id: null,
  position: null,
  rails_path: null,
  target_id: null,
  target_type: null,
  title: null,
  children: [],
  uniqueId: uniqueId(),
  expanded: true
})

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

    case ADD_ITEM:
      return {
        ...state,
        items: [
          ...state.items,
          makeItem()
        ]
      }

    case UPDATE_ITEMS:
      return {
        ...state,
        items: action.items
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

export default menusReducer
