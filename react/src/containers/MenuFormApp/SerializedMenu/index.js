import React from 'react'

function SerializedMenuItem ({ item, index }) {
  const prefix = `menu[menu_items_attributes][${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={item['id'] || ''} />
      <input type='hidden' name={name('title')} value={item['title'] || ''} />
      <input type='hidden' name={name('position')} value={index + 1} />
      <input type='hidden' name={name('rails_path')} value={item['rails_path'] || ''} />
      <input type='hidden' name={name('target_id')} value={item['target_id'] || ''} />
      <input type='hidden' name={name('target_type')} value={item['target_type'] || ''} />
      <input type='hidden' name={name('parent_unique_id')} value={item.parentUniqueId || ''} />
      <input type='hidden' name={name('unique_id')} value={item.uniqueId || ''} />
    </div>
  )
}

function SerializedRemovedMenuItem ({ id, index }) {
  const prefix = `menu[menu_items_attributes][${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={id} />
      <input type='hidden' name={name('_destroy')} value='1' />
    </div>
  )
}

const flatItems = (items) => {
  const flat = []

  const get = (item, parentUniqueId) => {
    flat.push({ ...item, parentUniqueId })
    item.children.forEach((child) => get(child, item.uniqueId))
  }
  items.forEach((item) => get(item, null))

  return flat
}

function SerializedMenu ({ menus }) {
  let i = -1
  const index = () => { i++; return i }

  return (
    <div hidden>
      {flatItems(menus.items).map((item) => (
        <SerializedMenuItem
          key={item.uniqueId}
          item={item}
          index={index()}
        />
      ))}

      {menus.removedIds.map((id) => (
        <SerializedRemovedMenuItem id={id} key={id} index={index()} />
      ))}
    </div>
  )
}

export default SerializedMenu
