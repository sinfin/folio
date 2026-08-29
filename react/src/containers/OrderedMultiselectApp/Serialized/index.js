import React from 'react'

function SerializedItem ({ item, index, paramBase, foreignKey, serializePosition }) {
  const prefix = `${paramBase}[${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={item['id'] || ''} />
      {serializePosition && <input type='hidden' name={name('position')} value={index + 1} />}
      <input type='hidden' name={name(foreignKey)} value={item.value || ''} />
    </div>
  )
}

function SerializedRemovedItem ({ id, index, paramBase }) {
  const prefix = `${paramBase}[${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={id} />
      <input type='hidden' name={name('_destroy')} value='1' />
    </div>
  )
}

function SerializedArrayItem ({ item, inputName }) {
  const value = item.value === undefined || item.value === null ? '' : item.value

  return (
    <input type='hidden' name={inputName} value={value} />
  )
}

function SerializedScalar ({ items, inputName }) {
  const item = items[0]
  const value = item && item.value !== undefined && item.value !== null ? item.value : ''

  return (
    <input type='hidden' name={inputName} value={value} />
  )
}

function Serialized ({ orderedMultiselect }) {
  const { paramBase, foreignKey, items, removedItems, sortable, serialization, inputName } = orderedMultiselect

  if (serialization === 'array') {
    return (
      <div hidden>
        <input type='hidden' name={inputName} value='' />

        {items.map((item) => (
          <SerializedArrayItem
            key={item.uniqueId}
            item={item}
            inputName={inputName}
          />
        ))}
      </div>
    )
  }

  if (serialization === 'scalar') {
    return (
      <div hidden>
        <SerializedScalar items={items} inputName={inputName} />
      </div>
    )
  }

  let i = -1
  const index = () => { i++; return i }

  return (
    <div hidden>
      {items.map((item) => (
        <SerializedItem
          key={item.uniqueId}
          item={item}
          index={index()}
          paramBase={paramBase}
          foreignKey={foreignKey}
          serializePosition={sortable}
        />
      ))}

      {removedItems.map((item) => (
        <SerializedRemovedItem
          key={item.uniqueId}
          id={item.id}
          index={index()}
          paramBase={paramBase}
        />
      ))}
    </div>
  )
}

export default Serialized
