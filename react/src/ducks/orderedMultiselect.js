import { uniqueId } from 'lodash'
import { select, takeLatest } from 'redux-saga/effects'

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

export function addItem (item) {
  return { type: ADD_ITEM, item }
}

export function updateItems (items) {
  return { type: UPDATE_ITEMS, items }
}

export function removeItem (item) {
  return { type: REMOVE_ITEM, item }
}

// Selectors

export const orderedMultiselectSelector = (state) => state.orderedMultiselect

// Sagas

function * triggerAtomSettingUpdate (action) {
  const orderedMultiselect = yield select(orderedMultiselectSelector)
  if (orderedMultiselect.atomSetting) {
    const $wrap = window.jQuery('.folio-react-wrap--ordered-multiselect')
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
  removedIds: [],
  paramBase: null,
  foreignKey: null,
  url: null,
  sortable: true,
  atomSetting: false
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

    case ADD_ITEM:
      return {
        ...state,
        items: [
          ...state.items,
          {
            id: null,
            label: action.item.label,
            value: action.item.id,
            uniqueId: uniqueId()
          }
        ]
      }

    case REMOVE_ITEM: {
      const removedIds = [...state.removedIds]
      if (action.item.id) removedIds.push(action.item.id)

      return {
        ...state,
        removedIds,
        items: state.items.filter((stateItem) => stateItem.uniqueId !== action.item.uniqueId)
      }
    }

    default:
      return state
  }
}

export default orderedMultiselectReducer
