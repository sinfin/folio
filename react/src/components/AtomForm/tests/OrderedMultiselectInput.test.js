import React from 'react'
import renderer, { act } from 'react-test-renderer'

import 'folioTestSetup'

import OrderedMultiselectInput from '../OrderedMultiselectInput'
import { OrderedMultiselectApp } from 'containers/OrderedMultiselectApp'
import { apiGet } from 'utils/api'

jest.mock('utils/api', () => ({ apiGet: jest.fn() }))
jest.mock('containers/OrderedMultiselectApp', () => ({
  OrderedMultiselectApp: () => null
}))

const atom = {
  errors: {},
  record: {
    data: { newsletter_codes: '["weekly"]' },
    meta: {
      structure: {
        newsletter_codes: {
          type: 'ordered_multiselect',
          options_url: '/console/options.json',
          load_error: 'Katalog newsletterů nyní není dostupný.',
          unavailable_label: '%{value} (unavailable)'
        }
      }
    }
  }
}

describe('OrderedMultiselectInput', () => {
  it('loads labels and serializes ordered values back to the atom', async () => {
    apiGet.mockResolvedValue({
      data: [
        { id: 'daily', value: 'daily', label: 'Daily' },
        { id: 'weekly', value: 'weekly', label: 'Weekly' }
      ]
    })
    const onValueChange = jest.fn()
    let component

    await act(async () => {
      component = renderer.create(
        <OrderedMultiselectInput
          atom={atom}
          field='newsletter_codes'
          index={0}
          onValueChange={onValueChange}
        />
      )
    })

    const input = component.root.findByType(OrderedMultiselectApp)
    expect(apiGet).toHaveBeenCalledWith('/console/options.json')
    expect(component.root.findByProps({ className: 'folio-react-wrap--ordered-multiselect form-control' })).toBeTruthy()
    expect(input.props.orderedMultiselect.items.map((item) => item.label)).toEqual(['Weekly'])

    input.props.addItem({ id: 'daily', label: 'Daily' })
    expect(onValueChange).toHaveBeenLastCalledWith(0, '["weekly","daily"]', 'newsletter_codes')

    input.props.updateItems([
      { value: 'daily' },
      { value: 'weekly' }
    ])
    expect(onValueChange).toHaveBeenLastCalledWith(0, '["daily","weekly"]', 'newsletter_codes')

    input.props.removeItem({ value: 'weekly' })
    expect(onValueChange).toHaveBeenLastCalledWith(0, '[]', 'newsletter_codes')
  })

  it('keeps selected values visible when loading options fails', async () => {
    apiGet.mockRejectedValue(new Error('unavailable'))
    let component

    await act(async () => {
      component = renderer.create(
        <OrderedMultiselectInput
          atom={atom}
          field='newsletter_codes'
          index={0}
          onValueChange={() => {}}
        />
      )
    })

    const input = component.root.findByType(OrderedMultiselectApp)
    expect(component.root.findByProps({ role: 'alert' }).children).toEqual([
      'Katalog newsletterů nyní není dostupný.'
    ])
    expect(input.props.orderedMultiselect.items.map((item) => item.label)).toEqual(['weekly (unavailable)'])
  })
})
