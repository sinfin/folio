import React from 'react'

function SerializedItem ({ item, index, paramBase, foreignKey }) {
  const prefix = `${paramBase}[${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={item['id'] || ''} />
      <input type='hidden' name={name('position')} value={index + 1} />
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

function Serialized ({ orderedMultiselect }) {
  const { paramBase, foreignKey, items, removedIds } = orderedMultiselect

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
        />
      ))}

      {removedIds.map((id) => (
        <SerializedRemovedItem
          id={id}
          key={id}
          index={index()}
          paramBase={paramBase}
          foreignKey={foreignKey}
        />
      ))}
    </div>
  )
}

export default Serialized
