import atomsReducer, {
  initialState,
  setAtomsData,
  updateAtomValue,
  updateAtomType
} from '../atoms'

const DATA = { atoms: { atoms: [{ id: 3, type: 'Folio::Text', position: 1, placement_type: 'Folio::Page', placement_id: 1, data: { model: '', content: '\u003cp\u003elorem ipsum asfjpoasf\u003c/p\u003e\u003cp\u003e\u003c/p\u003e\u003cp\u003easofjpasfasfasfas\u003c/p\u003e\u003cp\u003e\u003c/p\u003e\u003cp\u003easfasfasf\u003c/p\u003e\u003cp\u003e\u003c/p\u003e\u003cp\u003efoo\u003c/p\u003e' } }, { id: 4, type: 'Folio::Atom::Text', position: 2, placement_type: 'Folio::Page', placement_id: 1, data: { content: '\u003cp\u003elorem ipsum\u003c/p\u003e' } }, { id: 5, type: 'Folio::Atom::Text', position: 3, placement_type: 'Folio::Page', placement_id: 1, data: { content: '\u003cp\u003elorem ipsum\u003c/p\u003e' } }] }, namespace: 'page', structures: { 'Folio::Atom::Title': { structure: { title: { label: 'Název', validators: [{ class: 'ActiveRecord::Validations::PresenceValidator', options: {} }], type: 'string' } }, title: 'Titulek' }, 'Folio::Atom::Text': { structure: { content: { label: 'Obsah', validators: [{ class: 'ActiveRecord::Validations::PresenceValidator', options: {} }], type: 'richtext' } }, title: 'Text' }, 'Atom::Documents': { structure: { documents: { label: 'Documents', validators: [], type: true } }, title: 'Soubory' }, 'Atom::Gallery': { structure: { images: { label: 'Images', validators: [], type: true } }, title: 'Galerie' }, 'Atom::PageReference': { structure: { model: { label: 'Model', validators: [], type: 'relation', collection: [['DAM', 'Folio::Page -=- 7'], ['Hidden', 'Folio::Page -=- 6'], ['Noční obloha', 'Folio::Page -=- 2'], ['O nás', 'Folio::Page -=- 1'], ['Reference', 'Folio::Page -=- 3'], ['Smart Cities', 'Folio::Page -=- 4'], ['Vyvolej.to', 'Folio::Page -=- 5']] } }, title: 'Odkaz na stránku' }, 'Atom::TitlePerexText': { structure: { title: { label: 'Název', validators: [], type: 'string' }, perex: { label: 'Perex', validators: [], type: 'string' }, content: { label: 'Obsah', validators: [], type: 'string' } }, title: 'Title perex text' }, 'Atom::WithHint': { structure: { content: { label: 'Obsah', validators: [], type: 'string' } }, title: 'Text s nápovědou' }, 'Atom::SingleDocument': { structure: { document: { label: 'Document', validators: [], type: true } }, title: 'Soubor' }, 'Atom::ContentFree': { structure: {}, title: 'Bez obsahu' }, 'Atom::SingleImage': { structure: { cover: { label: 'Obrázek', validators: [], type: true } }, title: 'Obrázek' }, 'Atom::StringContent': { structure: { content: { label: 'Obsah', validators: [], type: 'string' } }, title: 'Plain-text obsah' }, 'Atom::PageReferenceWithRichtext': { structure: { content: { label: 'Obsah', validators: [], type: 'richtext' }, model: { label: 'Model', validators: [], type: 'relation', collection: [['DAM', 'Folio::Page -=- 7'], ['Hidden', 'Folio::Page -=- 6'], ['Noční obloha', 'Folio::Page -=- 2'], ['O nás', 'Folio::Page -=- 1'], ['Reference', 'Folio::Page -=- 3'], ['Smart Cities', 'Folio::Page -=- 4'], ['Vyvolej.to', 'Folio::Page -=- 5']] } }, title: 'Odkaz na stránku s redactorem' }, 'Atom::PageReferenceWithText': { structure: { content: { label: 'Obsah', validators: [], type: 'string' }, model: { label: 'Model', validators: [], type: 'relation', collection: [['DAM', 'Folio::Page -=- 7'], ['Hidden', 'Folio::Page -=- 6'], ['Noční obloha', 'Folio::Page -=- 2'], ['O nás', 'Folio::Page -=- 1'], ['Reference', 'Folio::Page -=- 3'], ['Smart Cities', 'Folio::Page -=- 4'], ['Vyvolej.to', 'Folio::Page -=- 5']] } }, title: 'Odkaz na stránku s textem' } } }

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

  it('updateAtomType', () => {
    state = atomsReducer(state, updateAtomValue('atoms', 0, 'content', 'foo'))
    expect(state.atoms.atoms[0].type).not.toEqual('Atom::PageReferenceWithRichtext')
    const newState = atomsReducer(state, updateAtomType('atoms', 0, 'Atom::PageReferenceWithRichtext', { content: 'foo' }))
    expect(newState.atoms.atoms[0].type).toEqual('Atom::PageReferenceWithRichtext')
    expect(newState.atoms.atoms[0].data.content).toEqual('foo')
  })
})
