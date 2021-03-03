export const SINGLE_LOCALE_ATOMS = { atoms: { atoms: [{ id: 1, type: 'Folio::Atom::Text', position: 1, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 2, type: 'Folio::Atom::Text', position: 2, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 3, type: 'Folio::Atom::Text', position: 3, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 4, type: 'Dummy::Atom::Moleculable', position: 4, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }, { id: 5, type: 'Dummy::Atom::Moleculable', position: 5, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }, { id: 6, type: 'Dummy::Atom::Moleculable', position: 6, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }] }, destroyedIds: { atoms: [] }, namespace: 'page', structures: { 'Folio::Atom::Title': { associations: {}, attachments: [], hint: null, structure: { title: { label: 'Název', hint: null, type: 'string' } }, title: 'Titulek' }, 'Folio::Atom::Text': { associations: {}, attachments: [], hint: null, structure: { content: { label: 'Obsah', hint: null, type: 'richtext' } }, title: 'Text' }, 'Dummy::Atom::Images': { associations: {}, attachments: [{ file_type: 'Folio::Image', key: 'image_placements_attributes', label: 'Images', plural: true }], hint: null, structure: { title: { label: 'Název', hint: null, type: 'string' } }, title: 'Gallery' }, 'Dummy::Atom::DaVinci': { associations: { page: { hint: null, label: 'Page', records: [{ id: 7, type: 'Folio::Page', label: 'DAM', value: 'Folio::Page -=- 7' }, { id: 6, type: 'Folio::Page', label: 'Hidden', value: 'Folio::Page -=- 6' }, { id: 2, type: 'Folio::Page', label: 'Noční obloha', value: 'Folio::Page -=- 2' }, { id: 1, type: 'Folio::Page', label: 'O nás', value: 'Folio::Page -=- 1' }, { id: 3, type: 'Folio::Page', label: 'Reference', value: 'Folio::Page -=- 3' }, { id: 4, type: 'Folio::Page', label: 'Smart Cities', value: 'Folio::Page -=- 4' }, { id: 5, type: 'Folio::Page', label: 'Vyvolej.to', value: 'Folio::Page -=- 5' }] } }, attachments: [{ file_type: 'Folio::Image', key: 'cover_placement_attributes', label: 'Obrázek', plural: false }, { file_type: 'Folio::Document', key: 'document_placement_attributes', label: 'Document', plural: false }], hint: null, structure: { string: { label: 'String', hint: null, type: 'string' }, text: { label: 'Text', hint: null, type: 'text' }, richtext: { label: 'Richtext', hint: null, type: 'richtext' }, code: { label: 'Code', hint: null, type: 'code' }, integer: { label: 'Integer', hint: null, type: 'integer' }, float: { label: 'Float', hint: null, type: 'float' }, date: { label: 'Date', hint: null, type: 'date' }, datetime: { label: 'Datetime', hint: null, type: 'datetime' }, color: { label: 'Color', hint: null, type: 'color' } }, title: 'Da vinci' }, 'Dummy::Atom::Moleculable': { associations: { page: { hint: null, label: 'Page', records: [{ id: 'dummy/molecule/moleculable', type: 'Folio::Page', label: 'DAM', value: 'Folio::Page -=- 7' }, { id: 6, type: 'Folio::Page', label: 'Hidden', value: 'Folio::Page -=- 6' }, { id: 2, type: 'Folio::Page', label: 'Noční obloha', value: 'Folio::Page -=- 2' }, { id: 1, type: 'Folio::Page', label: 'O nás', value: 'Folio::Page -=- 1' }, { id: 3, type: 'Folio::Page', label: 'Reference', value: 'Folio::Page -=- 3' }, { id: 4, type: 'Folio::Page', label: 'Smart Cities', value: 'Folio::Page -=- 4' }, { id: 5, type: 'Folio::Page', label: 'Vyvolej.to', value: 'Folio::Page -=- 5' }] } }, attachments: [{ file_type: 'Folio::Image', key: 'cover_placement_attributes', label: 'Obrázek', plural: false }, { file_type: 'Folio::Image', key: 'image_placements_attributes', label: 'Images', plural: true }], hint: null, structure: { title: { label: 'Název', hint: null, type: 'string' } }, title: 'Moleculable' } }, placementType: 'Folio::Page' }

export const MULTI_LOCALE_ATOMS = { atoms: { cs_atoms: [{ id: 1, type: 'Folio::Atom::Text', position: 1, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 2, type: 'Folio::Atom::Text', position: 2, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 3, type: 'Folio::Atom::Text', position: 3, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 4, type: 'Dummy::Atom::Moleculable', position: 4, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }, { id: 5, type: 'Dummy::Atom::Moleculable', position: 5, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }, { id: 6, type: 'Dummy::Atom::Moleculable', position: 6, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }], en_atoms: [{ id: 1, type: 'Folio::Atom::Text', position: 1, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 2, type: 'Folio::Atom::Text', position: 2, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 3, type: 'Folio::Atom::Text', position: 3, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: null, data: { content: 'lorem ipsum' } }, { id: 4, type: 'Dummy::Atom::Moleculable', position: 4, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }, { id: 5, type: 'Dummy::Atom::Moleculable', position: 5, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }, { id: 6, type: 'Dummy::Atom::Moleculable', position: 6, placement_type: 'Folio::Page', placement_id: 1, associations: {}, molecule: 'dummy/molecule/moleculable', data: { title: 'lorem ipsum' } }] }, destroyedIds: { cs_atoms: [], en_atoms: [] }, namespace: 'page', structures: { 'Folio::Atom::Title': { associations: {}, attachments: [], hint: null, structure: { title: { label: 'Název', hint: null, type: 'string' } }, title: 'Titulek' }, 'Folio::Atom::Text': { associations: {}, attachments: [], hint: null, structure: { content: { label: 'Obsah', hint: null, type: 'richtext' } }, title: 'Text' }, 'Dummy::Atom::Images': { associations: {}, attachments: [{ file_type: 'Folio::Image', key: 'image_placements_attributes', label: 'Images', plural: true }], hint: null, structure: { title: { label: 'Název', hint: null, type: 'string' } }, title: 'Gallery' }, 'Dummy::Atom::DaVinci': { associations: { page: { hint: null, label: 'Page', records: [{ id: 7, type: 'Folio::Page', label: 'DAM', value: 'Folio::Page -=- 7' }, { id: 6, type: 'Folio::Page', label: 'Hidden', value: 'Folio::Page -=- 6' }, { id: 2, type: 'Folio::Page', label: 'Noční obloha', value: 'Folio::Page -=- 2' }, { id: 1, type: 'Folio::Page', label: 'O nás', value: 'Folio::Page -=- 1' }, { id: 3, type: 'Folio::Page', label: 'Reference', value: 'Folio::Page -=- 3' }, { id: 4, type: 'Folio::Page', label: 'Smart Cities', value: 'Folio::Page -=- 4' }, { id: 5, type: 'Folio::Page', label: 'Vyvolej.to', value: 'Folio::Page -=- 5' }] } }, attachments: [{ file_type: 'Folio::Image', key: 'cover_placement_attributes', label: 'Obrázek', plural: false }, { file_type: 'Folio::Document', key: 'document_placement_attributes', label: 'Document', plural: false }], hint: null, structure: { string: { label: 'String', hint: null, type: 'string' }, text: { label: 'Text', hint: null, type: 'text' }, richtext: { label: 'Richtext', hint: null, type: 'richtext' }, code: { label: 'Code', hint: null, type: 'code' }, integer: { label: 'Integer', hint: null, type: 'integer' }, float: { label: 'Float', hint: null, type: 'float' }, date: { label: 'Date', hint: null, type: 'date' }, datetime: { label: 'Datetime', hint: null, type: 'datetime' }, color: { label: 'Color', hint: null, type: 'color' } }, title: 'Da vinci' }, 'Dummy::Atom::Moleculable': { associations: { page: { hint: null, label: 'Page', records: [{ id: 'dummy/molecule/moleculable', type: 'Folio::Page', label: 'DAM', value: 'Folio::Page -=- 7' }, { id: 6, type: 'Folio::Page', label: 'Hidden', value: 'Folio::Page -=- 6' }, { id: 2, type: 'Folio::Page', label: 'Noční obloha', value: 'Folio::Page -=- 2' }, { id: 1, type: 'Folio::Page', label: 'O nás', value: 'Folio::Page -=- 1' }, { id: 3, type: 'Folio::Page', label: 'Reference', value: 'Folio::Page -=- 3' }, { id: 4, type: 'Folio::Page', label: 'Smart Cities', value: 'Folio::Page -=- 4' }, { id: 5, type: 'Folio::Page', label: 'Vyvolej.to', value: 'Folio::Page -=- 5' }] } }, attachments: [{ file_type: 'Folio::Image', key: 'cover_placement_attributes', label: 'Obrázek', plural: false }, { file_type: 'Folio::Image', key: 'image_placements_attributes', label: 'Images', plural: true }], hint: null, structure: { title: { label: 'Název', hint: null, type: 'string' } }, title: 'Moleculable' } }, placementType: 'Folio::Page' }
