import { arrayMove } from 'react-sortable-hoc'
import { find, filter } from 'lodash'
import { takeEvery } from 'redux-saga/effects'

import { makeFilesSelector } from 'ducks/files'

// Constants

const SET_ORIGINAL_PLACEMENTS = 'filePlacements/SET_ORIGINAL_PLACEMENTS'
const SELECT_FILE = 'filePlacements/SELECT_FILE'
const UNSELECT_FILE_PLACEMENT = 'filePlacements/UNSELECT_FILE_PLACEMENT'
const ON_SORT_END = 'filePlacements/ON_SORT_END'
const SET_ATTACHMENTABLE = 'filePlacements/SET_ATTACHMENTABLE'
const SET_PLACEMENT_TYPE = 'filePlacements/SET_PLACEMENT_TYPE'
const CHANGE_TITLE = 'filePlacements/CHANGE_TITLE'
const CHANGE_ALT = 'filePlacements/CHANGE_ALT'

// Actions

export function setOriginalPlacements (fileType, original) {
  return { type: SET_ORIGINAL_PLACEMENTS, fileType, original }
}

export function setAttachmentable (fileType, attachmentable) {
  return { type: SET_ATTACHMENTABLE, fileType, attachmentable }
}

export function selectFile (fileType, file) {
  return { type: SELECT_FILE, fileType, file }
}

export function unselectFilePlacement (fileType, filePlacement) {
  return { type: UNSELECT_FILE_PLACEMENT, fileType, filePlacement }
}

export function onSortEnd (fileType, oldIndex, newIndex) {
  return { type: ON_SORT_END, fileType, oldIndex, newIndex }
}

export function setPlacementType (fileType, placementType) {
  return { type: SET_PLACEMENT_TYPE, fileType, placementType }
}

export function changeTitle (fileType, filePlacement, title) {
  return { type: CHANGE_TITLE, fileType, filePlacement, title }
}

export function changeAlt (fileType, filePlacement, alt) {
  return { type: CHANGE_ALT, fileType, filePlacement, alt }
}

// Selectors

export const makeSelectedFileIdsSelector = (fileType) => (state) => {
  const base = state.filePlacements[fileType] || defaultFilePlacementsKeyState
  return base.selected.map((filePlacement) => String(filePlacement.file_id))
}

export const makeFilePlacementsSelector = (fileType) => (state) => {
  const base = state.filePlacements[fileType] || defaultFilePlacementsKeyState
  const files = makeFilesSelector(fileType)(state)
  const selectedIds = []

  const selected = base.selected.map((filePlacement) => {
    selectedIds.push(filePlacement.id)
    const file = find(files, { id: String(filePlacement.file_id) })
    if (file) {
      return { ...filePlacement, file }
    } else {
      return filePlacement
    }
  })

  const deleted = filter(base.original, (filePlacement) => (
    selectedIds.indexOf(filePlacement.id) === -1
  ))

  return {
    selected,
    deleted,
    attachmentable: base.attachmentable,
    placementType: base.placementType
  }
}

// Sagas
function * triggerWrapChangeEvent (action) {
  // used to update atom previews via the data-atom-setting functionality
  yield window.jQuery('.f-c-js-atoms-placement-setting.folio-react-wrap').trigger('folioCustomChange')
}

function * triggerWrapChangeEventSaga () {
  yield [
    takeEvery(SELECT_FILE, triggerWrapChangeEvent),
    takeEvery(UNSELECT_FILE_PLACEMENT, triggerWrapChangeEvent),
    takeEvery(ON_SORT_END, triggerWrapChangeEvent),
    takeEvery(CHANGE_TITLE, triggerWrapChangeEvent),
    takeEvery(CHANGE_ALT, triggerWrapChangeEvent)
  ]
}

export const filePlacementsSagas = [
  triggerWrapChangeEventSaga
]

// State

const defaultFilePlacementsKeyState = {
  original: [],
  selected: [],
  attachmentable: 'page',
  placementType: 'document_placements'
}

export const initialState = {}

// Reducer

function filePlacementsReducer (rawState = initialState, action) {
  const state = rawState

  if (action.fileType && !state[action.fileType]) {
    state[action.fileType] = { ...defaultFilePlacementsKeyState }
  }

  switch (action.type) {
    case SET_ORIGINAL_PLACEMENTS:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          original: action.original,
          selected: action.original
        }
      }

    case SET_ATTACHMENTABLE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          attachmentable: action.attachmentable
        }
      }

    case SELECT_FILE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          selected: [
            ...state[action.fileType].selected,
            {
              id: null,
              file_id: action.file.id,
              file: action.file,
              selectedAt: Date.now()
            }
          ]
        }
      }

    case UNSELECT_FILE_PLACEMENT:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          selected: state[action.fileType].selected.filter((filePlacement) => (
            filePlacement.file_id !== action.filePlacement.file_id
          ))
        }
      }

    case ON_SORT_END:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          selected: arrayMove(state[action.fileType].selected, action.oldIndex, action.newIndex)
        }
      }

    case SET_PLACEMENT_TYPE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          placementType: action.placementType
        }
      }

    case CHANGE_TITLE:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          selected: state[action.fileType].selected.map((filePlacement) => {
            if (filePlacement.file_id === action.filePlacement.file_id) {
              return {
                ...filePlacement,
                title: action.title
              }
            } else {
              return filePlacement
            }
          })
        }
      }

    case CHANGE_ALT:
      return {
        ...state,
        [action.fileType]: {
          ...state[action.fileType],
          selected: state[action.fileType].selected.map((filePlacement) => {
            if (filePlacement.file_id === action.filePlacement.file_id) {
              return {
                ...filePlacement,
                alt: action.alt
              }
            } else {
              return filePlacement
            }
          })
        }
      }

    default:
      return state
  }
}

export default filePlacementsReducer
