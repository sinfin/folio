import 'folioTestSetup'

import filtersReducer, {
  initialState,
  setFilter,
  unsetFilter,
  resetFilters
} from '../filters'

describe('filtersReducer', () => {
  let state

  beforeEach(() => {
    state = filtersReducer(initialState, setFilter('Folio::File::Image', '/console/api/images', 'tags', ['a']))
  })

  it('setFilter', () => {
    expect(state['Folio::File::Image'].tags).toEqual(['a'])
  })

  it('unsetFilter', () => {
    state = filtersReducer(state, unsetFilter('Folio::File::Image', '/console/api/images', 'tags'))
    expect(state['Folio::File::Image'].tags).toEqual([])
  })

  it('resetFilters', () => {
    state = filtersReducer(state, resetFilters('Folio::File::Image', '/console/api/images'))
    expect(state['Folio::File::Image'].tags).toEqual([])
  })
})
