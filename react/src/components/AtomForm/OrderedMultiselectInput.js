import React from 'react'

import { OrderedMultiselectApp } from 'containers/OrderedMultiselectApp'
import { apiGet } from 'utils/api'

const parseValues = (value) => {
  try {
    const parsed = JSON.parse(value || '[]')
    return Array.isArray(parsed) ? [...new Set(parsed.map(String).filter(Boolean))] : []
  } catch (_error) {
    return []
  }
}

const unavailableLabel = (template, value) => {
  return template ? template.replace('%{value}', value) : value
}

export default function OrderedMultiselectInput ({ atom, field, index, onValueChange }) {
  const config = atom.record.meta.structure[field]
  const values = parseValues(atom.record.data[field])
  const [options, setOptions] = React.useState(config.options || (config.options_url ? null : []))
  const [loadFailed, setLoadFailed] = React.useState(false)

  React.useEffect(() => {
    if (!config.options_url) return

    let mounted = true
    setLoadFailed(false)

    apiGet(config.options_url)
      .then((response) => {
        if (mounted) setOptions(response.data || [])
      })
      .catch(() => {
        if (mounted) {
          setOptions([])
          setLoadFailed(true)
        }
      })

    return () => { mounted = false }
  }, [config.options_url])

  if (options === null) {
    return (
      <div className='folio-react-wrap--ordered-multiselect form-control'>
        <span className='folio-loader' />
      </div>
    )
  }

  const optionByValue = new Map(options.map((option) => [String(option.value), option]))
  const items = values.map((value) => ({
    id: null,
    label: optionByValue.get(value)?.label || unavailableLabel(config.unavailable_label, value),
    uniqueId: value,
    value
  }))
  const commit = (newValues) => {
    onValueChange(index, JSON.stringify(newValues.map(String)), field)
  }

  return (
    <React.Fragment>
      {loadFailed && config.load_error ? (
        <div className='alert alert-warning' role='alert'>{config.load_error}</div>
      ) : null}

      <div className='folio-react-wrap--ordered-multiselect form-control'>
        <OrderedMultiselectApp
          orderedMultiselect={{
            atomSetting: false,
            items,
            maxItems: config.max_items || null,
            menuPlacement: config.menu_placement || 'bottom',
            options,
            removedItems: [],
            sortable: config.sortable !== false
          }}
          addItem={(item) => commit([...values, item.id])}
          updateItems={(newItems) => commit(newItems.map((item) => item.value))}
          removeItem={(item) => commit(values.filter((value) => value !== String(item.value)))}
          serialize={false}
        />
      </div>
    </React.Fragment>
  )
}
