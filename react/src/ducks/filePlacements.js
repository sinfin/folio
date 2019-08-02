import { arrayMove } from 'react-sortable-hoc'
import { find, filter } from 'lodash'

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

export function setOriginalPlacements (filesKey, original) {
  return { type: SET_ORIGINAL_PLACEMENTS, filesKey, original }
}

export function setAttachmentable (filesKey, attachmentable) {
  return { type: SET_ATTACHMENTABLE, filesKey, attachmentable }
}

export function selectFile (filesKey, file) {
  return { type: SELECT_FILE, filesKey, file }
}

export function unselectFilePlacement (filesKey, filePlacement) {
  return { type: UNSELECT_FILE_PLACEMENT, filesKey, filePlacement }
}

export function onSortEnd (filesKey, oldIndex, newIndex) {
  return { type: ON_SORT_END, filesKey, oldIndex, newIndex }
}

export function setPlacementType (filesKey, placementType) {
  return { type: SET_PLACEMENT_TYPE, filesKey, placementType }
}

export function changeTitle (filesKey, filePlacement, title) {
  return { type: CHANGE_TITLE, filesKey, filePlacement, title }
}

export function changeAlt (filesKey, filePlacement, alt) {
  return { type: CHANGE_ALT, filesKey, filePlacement, alt }
}

// Selectors

export const makeSelectedFileIdsSelector = (filesKey) => (state) => {
  const base = state.filePlacements[filesKey]
  return base.selected.map((filePlacement) => filePlacement.file_id)
}

export const makeFilePlacementsSelector = (filesKey) => (state) => {
  const base = state.filePlacements[filesKey]
  const files = makeFilesSelector(filesKey)(state)
  const selectedIds = []

  const selected = base.selected.map((filePlacement) => {
    selectedIds.push(filePlacement.id)
    const file = find(files, { id: String(filePlacement.file_id) })
    return {
      ...filePlacement,
      file: file
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

// State

export const initialState = {
  documents: {
    original: [],
    selected: [],
    attachmentable: 'page',
    placementType: 'document_placements'
  },
  images: {
    original: [],
    selected: [],
    attachmentable: 'page',
    placementType: 'image_placements'
  }
}

// Reducer

function filePlacementsReducer (state = initialState, action) {
  switch (action.type) {
    case SET_ORIGINAL_PLACEMENTS:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          original: action.original,
          selected: action.original
        }
      }

    case SET_ATTACHMENTABLE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          attachmentable: action.attachmentable
        }
      }

    case SELECT_FILE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          selected: [
            ...state[action.filesKey].selected,
            { id: null, file_id: action.file.id, selectedAt: Date.now() }
          ]
        }
      }

    case UNSELECT_FILE_PLACEMENT:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          selected: state[action.filesKey].selected.filter((filePlacement) => filePlacement.file_id !== action.filePlacement.file_id)
        }
      }

    case ON_SORT_END:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          selected: arrayMove(state[action.filesKey].selected, action.oldIndex, action.newIndex)
        }
      }

    case SET_PLACEMENT_TYPE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          placementType: action.placementType
        }
      }

    case CHANGE_TITLE:
      return {
        ...state,
        [action.filesKey]: {
          ...state[action.filesKey],
          selected: state[action.filesKey].selected.map((filePlacement) => {
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
        [action.filesKey]: {
          ...state[action.filesKey],
          selected: state[action.filesKey].selected.map((filePlacement) => {
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
