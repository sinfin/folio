import 'folioTestSetup'

import filtersReducer, {
  initialState,
  setFilter,
  unsetFilter,
  resetFilters,
  makeFiltersQuerySelector
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

  it('generates by_query parameter for query filter', () => {
    state = filtersReducer(initialState, setFilter('Folio::File::Image', '/console/api/images', 'query', 'Pardubice'))
    const selector = makeFiltersQuerySelector('Folio::File::Image')
    const queryString = selector({ filters: state })

    expect(queryString).toContain('by_query=Pardubice')
  })

  it('generates by_tags parameter for tags filter', () => {
    state = filtersReducer(initialState, setFilter('Folio::File::Image', '/console/api/images', 'tags', ['architecture', 'nature']))
    const selector = makeFiltersQuerySelector('Folio::File::Image')
    const queryString = selector({ filters: state })

    expect(queryString).toContain('by_tags=architecture%2Cnature')
  })
})
