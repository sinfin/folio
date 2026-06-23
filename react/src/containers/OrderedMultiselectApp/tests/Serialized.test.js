import React from 'react'
import renderer from 'react-test-renderer'

import 'folioTestSetup'

import Serialized from '../Serialized'

describe('OrderedMultiselectApp Serialized', () => {
  it('renders nested attributes by default', () => {
    const orderedMultiselect = {
      paramBase: 'dummy_blog_article[author_article_links_attributes]',
      foreignKey: 'dummy_blog_author_id',
      items: [
        { uniqueId: 'first', id: 7, value: 123 }
      ],
      removedItems: [
        { uniqueId: 'removed', id: 8 }
      ],
      sortable: true
    }

    const component = renderer.create(<Serialized orderedMultiselect={orderedMultiselect} />)
    const inputs = component.root.findAllByType('input').map((input) => input.props)

    expect(inputs.map((input) => [input.name, input.value])).toEqual([
      ['dummy_blog_article[author_article_links_attributes][1][id]', 7],
      ['dummy_blog_article[author_article_links_attributes][1][position]', 1],
      ['dummy_blog_article[author_article_links_attributes][1][dummy_blog_author_id]', 123],
      ['dummy_blog_article[author_article_links_attributes][2][id]', 8],
      ['dummy_blog_article[author_article_links_attributes][2][_destroy]', '1']
    ])
  })

  it('renders array values with a blank hidden input', () => {
    const orderedMultiselect = {
      serialization: 'array',
      inputName: 'economia_article[issue_ids][]',
      items: [
        { uniqueId: 'first', value: 123 },
        { uniqueId: 'second', value: 456 }
      ],
      removedItems: [
        { uniqueId: 'removed', id: 8, value: 789 }
      ]
    }

    const component = renderer.create(<Serialized orderedMultiselect={orderedMultiselect} />)
    const inputs = component.root.findAllByType('input').map((input) => input.props)

    expect(inputs.map((input) => [input.name, input.value])).toEqual([
      ['economia_article[issue_ids][]', ''],
      ['economia_article[issue_ids][]', 123],
      ['economia_article[issue_ids][]', 456]
    ])
  })
})
