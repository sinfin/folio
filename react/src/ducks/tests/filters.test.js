import filtersReducer, {
  initialState,
  setFilter,
  unsetFilter,
  resetFilters
} from '../filters'

describe('filtersReducer', () => {
  let state

  beforeEach(() => {
    state = filtersReducer(state, setFilter('images', 'tags', ['a']))
  })

  it('setFilter', () => {
    expect(state['images'].tags).toEqual(['a'])
  })

  it('unsetFilter', () => {
    state = filtersReducer(state, unsetFilter('images', 'tags'))
    expect(state['images'].tags).toEqual([])
  })

  it('resetFilters', () => {
    state = filtersReducer(state, resetFilters('images'))
    expect(state['images'].tags).toEqual([])
  })
})
