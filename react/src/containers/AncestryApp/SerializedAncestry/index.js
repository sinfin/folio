import React from 'react'

function SerializedItem ({ item, index }) {
  const prefix = `ancestry[${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={item.id} />
      <input type='hidden' name={name('position')} value={index + 1} />
      <input type='hidden' name={name('parent_id')} value={item.parentId || ''} />
    </div>
  )
}

const flatItems = (items) => {
  const flat = []

  const get = (item, parentId) => {
    flat.push({ ...item, parentId })
    item.children.forEach((child) => get(child, item.id))
  }
  items.forEach((item) => get(item, null))

  return flat
}

function SerializedAncestry ({ ancestry }) {
  let i = -1
  const index = () => { i++; return i }

  return (
    <div hidden>
      {flatItems(ancestry.items).map((item) => (
        <SerializedItem
          key={item.id}
          item={item}
          index={index()}
        />
      ))}
    </div>
  )
}

export default SerializedAncestry
