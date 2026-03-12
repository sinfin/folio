import isDuplicateLabel from 'utils/isDuplicateLabel'

// ---------------------------------------------------------------------------
// isDuplicateLabel(value, currentLabel, existingLabels, loadedOptions)
//
// Returns true when `value` matches something other than currentLabel.
// Checks: existingLabels (selected items) + loadedOptions (unselected DB items)
// ---------------------------------------------------------------------------

describe('isDuplicateLabel', () => {
  const selected = ['Foo', 'Bar']
  const loaded = [{ label: 'Baz' }, { label: 'Qux' }]

  test('returns false for empty input', () => {
    expect(isDuplicateLabel('', 'Foo', selected, loaded)).toBe(false)
    expect(isDuplicateLabel('   ', 'Foo', selected, loaded)).toBe(false)
  })

  test('returns false when value matches currentLabel (not a real duplicate)', () => {
    expect(isDuplicateLabel('Foo', 'Foo', selected, loaded)).toBe(false)
  })

  test('is case-insensitive', () => {
    expect(isDuplicateLabel('FOO', 'CurrentThing', selected, loaded)).toBe(true)
    expect(isDuplicateLabel('foo', 'CurrentThing', selected, loaded)).toBe(true)
    expect(isDuplicateLabel('BAZ', 'CurrentThing', selected, loaded)).toBe(true)
    expect(isDuplicateLabel('baz', 'CurrentThing', selected, loaded)).toBe(true)
  })

  test('trims whitespace before comparing', () => {
    expect(isDuplicateLabel('  Foo  ', 'CurrentThing', selected, loaded)).toBe(true)
    expect(isDuplicateLabel('  Baz  ', 'CurrentThing', selected, loaded)).toBe(true)
  })

  test('detects duplicates in existingLabels (already-selected items)', () => {
    expect(isDuplicateLabel('Bar', 'CurrentThing', selected, loaded)).toBe(true)
  })

  test('detects duplicates in loadedOptions (unselected DB items)', () => {
    expect(isDuplicateLabel('Qux', 'CurrentThing', selected, loaded)).toBe(true)
  })

  test('returns false for a genuinely new label', () => {
    expect(isDuplicateLabel('Brand New', 'CurrentThing', selected, loaded)).toBe(false)
  })

  test('handles null/undefined existingLabels gracefully', () => {
    expect(isDuplicateLabel('Baz', 'CurrentThing', null, loaded)).toBe(true)
    expect(isDuplicateLabel('Baz', 'CurrentThing', undefined, loaded)).toBe(true)
  })

  test('handles null/undefined loadedOptions gracefully', () => {
    expect(isDuplicateLabel('Foo', 'CurrentThing', selected, null)).toBe(true)
    expect(isDuplicateLabel('Foo', 'CurrentThing', selected, undefined)).toBe(true)
  })

  test('handles loadedOptions entries without a label', () => {
    const malformed = [{ value: 5 }, { label: 'Valid' }]
    expect(isDuplicateLabel('Valid', 'CurrentThing', [], malformed)).toBe(true)
    // entry without label should not throw
    expect(isDuplicateLabel('something', 'CurrentThing', [], malformed)).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// isValidNewOption logic (extracted to keep it independently testable)
//
// Mirrors the method in Select/index.js so we can test all edge cases without
// rendering the full React component.
// ---------------------------------------------------------------------------

function isValidNewOption (inputValue, existingLabels, selectOptions, loadedOptions) {
  if (!inputValue) return false
  const normalized = inputValue.toLowerCase().trim()

  if (existingLabels) {
    for (const label of existingLabels) {
      if (label.toLowerCase().trim() === normalized) return false
    }
  }

  for (const opt of selectOptions) {
    if (opt.label && opt.label.toLowerCase().trim() === normalized) return false
  }

  for (const opt of loadedOptions) {
    if (opt.label && opt.label.toLowerCase().trim() === normalized) return false
  }

  return true
}

describe('isValidNewOption', () => {
  test('returns false for empty input', () => {
    expect(isValidNewOption('', [], [], [])).toBe(false)
    expect(isValidNewOption(null, [], [], [])).toBe(false)
  })

  test('returns true for a genuinely new value', () => {
    expect(isValidNewOption('New Tag', ['Existing'], [{ label: 'Other' }], [])).toBe(true)
  })

  test('returns false when input matches existingLabels (selected items)', () => {
    expect(isValidNewOption('Foo', ['Foo', 'Bar'], [], [])).toBe(false)
    expect(isValidNewOption('foo', ['Foo'], [], [])).toBe(false)  // case-insensitive
  })

  test('returns false when input matches selectOptions (current dropdown)', () => {
    const dropdownOptions = [{ label: 'Baz' }, { label: 'Qux' }]
    expect(isValidNewOption('Baz', [], dropdownOptions, [])).toBe(false)
  })

  test('returns false when input matches loadedOptions (previous API response)', () => {
    // This is the timing-gap bug: selectOptions may be stale during debounce,
    // but loadedOptions holds the last completed API response
    const loadedOptions = [{ label: 'DbItem', value: 7 }]
    expect(isValidNewOption('DbItem', [], [], loadedOptions)).toBe(false)
    expect(isValidNewOption('dbitem', [], [], loadedOptions)).toBe(false)  // case-insensitive
  })

  test('timing gap scenario: selectOptions stale but loadedOptions current', () => {
    // User types "Foo", debounce window active, selectOptions is from previous
    // query (empty) but loadedOptions has the item from initial load
    const staleSelectOptions = []
    const loadedFromInitialLoad = [{ label: 'Foo', value: 1 }, { label: 'Bar', value: 2 }]
    expect(isValidNewOption('Foo', [], staleSelectOptions, loadedFromInitialLoad)).toBe(false)
  })
})
