import { uniqueId } from 'lodash'
import { select, takeLatest } from 'redux-saga/effects'

// Constants

const SET_ORDERED_MULTISELECT_DATA = 'orderedMultiselect/SET_ORDERED_MULTISELECT_DATA'
const ADD_ITEM = 'orderedMultiselect/ADD_ITEM'
const UPDATE_ITEMS = 'orderedMultiselect/UPDATE_ITEMS'
const REMOVE_ITEM = 'orderedMultiselect/REMOVE_ITEM'
const RENAME_ITEM = 'orderedMultiselect/RENAME_ITEM'
const REMOVE_DELETED_ITEM = 'orderedMultiselect/REMOVE_DELETED_ITEM'

export const MENU_ITEM_URL = 'orderedMultiselect/MENU_ITEM_URL'

// Actions

export function setOrderedMultiselectData (data) {
  return { type: SET_ORDERED_MULTISELECT_DATA, data }
}

export function addItem (item) {
  return { type: ADD_ITEM, item }
}

export function updateItems (items) {
  return { type: UPDATE_ITEMS, items }
}

export function removeItem (item) {
  return { type: REMOVE_ITEM, item }
}

export function renameItem (itemValue, newLabel) {
  return { type: RENAME_ITEM, itemValue, newLabel }
}

export function removeDeletedItem (itemValue) {
  return { type: REMOVE_DELETED_ITEM, itemValue }
}

// Selectors

export const orderedMultiselectSelector = (state) => state.orderedMultiselect

// Sagas

function * triggerAtomSettingUpdate (action) {
  const orderedMultiselect = yield select(orderedMultiselectSelector)
  if (orderedMultiselect.atomSetting) {
    const $wrap = window.jQuery('.folio-react-wrap--ordered-multiselect').eq(0)
    $wrap.find('.f-c-js-atoms-placement-setting').trigger('folioCustomChange')
    const form = $wrap.closest('.f-c-simple-form-with-atoms__form, .f-c-dirty-simple-form')[0]
    if (form) form.dispatchEvent(new window.Event('change', { bubbles: true }))
    yield $wrap
  }
}

function * triggerAtomSettingUpdateSaga () {
  yield takeLatest([ADD_ITEM, UPDATE_ITEMS, REMOVE_ITEM], triggerAtomSettingUpdate)
}

export const orderedMultiselectSagas = [
  triggerAtomSettingUpdateSaga
]

// State

const initialState = {
  items: [],
  removedItems: [],
  paramBase: null,
  foreignKey: null,
  url: null,
  sortable: true,
  atomSetting: false,
  createable: false,
  createUrl: null,
  updateUrl: null,
  deleteUrl: null
}

// Reducer

function orderedMultiselectReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ORDERED_MULTISELECT_DATA: {
      return {
        ...state,
        ...action.data,
        items: action.data.items.map((item) => ({
          ...item,
          uniqueId: uniqueId()
        }))
      }
    }

    case UPDATE_ITEMS:
      return {
        ...state,
        items: action.items
      }

    case ADD_ITEM: {
      const existingItem = state.items.find((item) => item.value === action.item.id)
      if (existingItem) return state

      const removedItem = state.removedItems.find((item) => item.value === action.item.id)
      let removedItems = state.removedItems

      if (removedItem) {
        removedItems = removedItems.filter((item) => item.value !== action.item.id)
      }

      const item = removedItem || {
        id: null,
        label: action.item.label,
        value: action.item.id,
        uniqueId: uniqueId()
      }

      return {
        ...state,
        removedItems,
        items: [
          ...state.items.filter((stateItem) => stateItem.value !== action.item.id),
          item
        ]
      }
    }

    case REMOVE_ITEM: {
      const removedItems = [...state.removedItems]

      if (action.item.id) {
        removedItems.push(action.item)
      }

      return {
        ...state,
        removedItems,
        items: state.items.filter((stateItem) => stateItem.uniqueId !== action.item.uniqueId)
      }
    }

    case RENAME_ITEM: {
      return {
        ...state,
        items: state.items.map((item) => {
          if (String(item.value) === String(action.itemValue)) {
            return { ...item, label: action.newLabel }
          }
          return item
        })
      }
    }

    case REMOVE_DELETED_ITEM: {
      return {
        ...state,
        items: state.items.filter((item) => String(item.value) !== String(action.itemValue)),
        removedItems: state.removedItems.filter((item) => String(item.value) !== String(action.itemValue))
      }
    }

    default:
      return state
  }
}

export default orderedMultiselectReducer
