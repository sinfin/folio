import React from 'react'

function Entry ({ data, index, paramBase }) {
  const prefix = `${paramBase}[${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      {Object.keys(data).map((key) => (
        key === 'uniqueId' ? null : (
          <input key={key} type='hidden' name={name(key)} value={data[key] || ''} />
        )
      ))}
    </div>
  )
}

function Serialized ({ paramBase, serializedNotes }) {
  let i = -1
  const index = () => { i++; return i }

  return (
    <div hidden className='f-c-r-notes-fields-app__serialized'>
      {serializedNotes.map((data) => (
        <Entry
          key={data.uniqueId || `id-${data.id}`}
          data={data}
          paramBase={paramBase}
          index={index()}
        />
      ))}
    </div>
  )
}

export default Serialized
