import atomsReducer, {
  initialState,
  setAtomsData,
  updateAtomValue
} from '../atoms'

const DATA = { atoms: { atoms: [{ id: 3, type: 'Folio::Atom::Text', position: 1, placement_type: 'Folio::Page', placement_id: 1, data: { content: 'lorem ipsum' } }, { id: 4, type: 'Folio::Atom::Text', position: 2, placement_type: 'Folio::Page', placement_id: 1, data: { content: 'lorem ipsum' } }, { id: 5, type: 'Folio::Atom::Text', position: 3, placement_type: 'Folio::Page', placement_id: 1, data: { content: 'lorem ipsum' } }] }, namespace: 'page', structures: { 'Folio::Atom::Title': { structure: { title: { type: 'string', validators: [{ class: 'ActiveRecord::Validations::PresenceValidator', options: {} }] } }, title: 'Titulek' }, 'Folio::Atom::Text': { structure: { content: { type: 'richtext', validators: [{ class: 'ActiveRecord::Validations::PresenceValidator', options: {} }] } }, title: 'Text' }, 'Atom::Documents': { structure: { documents: { type: true, validators: [] } }, title: 'Soubory' }, 'Atom::Gallery': { structure: { images: { type: true, validators: [] } }, title: 'Galerie' }, 'Atom::PageReference': { structure: { model: { type: ['Folio::Page'], validators: [] } }, title: 'Odkaz na stránku' }, 'Atom::TitlePerexText': { structure: { title: { type: 'string', validators: [] }, perex: { type: 'string', validators: [] }, content: { type: 'string', validators: [] } }, title: 'Title perex text' }, 'Atom::WithHint': { structure: { content: { type: 'string', validators: [] } }, title: 'Text s nápovědou' }, 'Atom::SingleDocument': { structure: { document: { type: true, validators: [] } }, title: 'Soubor' }, 'Atom::ContentFree': { structure: {}, title: 'Bez obsahu' }, 'Atom::SingleImage': { structure: { cover: { type: true, validators: [] } }, title: 'Obrázek' }, 'Atom::StringContent': { structure: { content: { type: 'string', validators: [] } }, title: 'Plain-text obsah' }, 'Atom::PageReferenceWithRichtext': { structure: { content: { type: 'richtext', validators: [] }, model: { type: ['Folio::Page'], validators: [] } }, title: 'Odkaz na stránku s redactorem' }, 'Atom::PageReferenceWithText': { structure: { content: { type: 'string', validators: [] }, model: { type: ['Folio::Page'], validators: [] } }, title: 'Odkaz na stránku s textem' } } }

describe('atomsReducer', () => {
  let state

  beforeEach(() => {
    state = atomsReducer(initialState, setAtomsData(DATA))
  })

  it('setAtomsData', () => {
    expect(state.namespace).toEqual('page')
    expect(state.atoms.atoms.length).toEqual(3)
  })

  it('updateAtomValue', () => {
    expect(state.atoms.atoms[0].data.content).not.toEqual('foo')
    const newState = atomsReducer(state, updateAtomValue('atoms', 0, 'content', 'foo'))
    expect(newState.atoms.atoms[0].data.content).toEqual('foo')
  })
})
