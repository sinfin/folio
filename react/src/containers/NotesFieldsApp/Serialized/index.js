import React from 'react'

function SerializedNote ({ note, index, paramBase }) {
  const prefix = `${paramBase}[${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={note.id || ''} />
      <input type='hidden' name={name('position')} value={index + 1} />
      <input type='hidden' name={name('content')} value={note.attributes.content || ''} />
      <input type='hidden' name={name('created_by_id')} value={note.attributes.created_by_id || ''} />
      <input type='hidden' name={name('closed_by_id')} value={note.attributes.closed_by_id || ''} />
      <input type='hidden' name={name('closed_at')} value={note.attributes.closed_at ? note.attributes.closed_at.toISOString() : ''} />
      <input type='hidden' name={name('due_at')} value={note.attributes.due_at ? note.attributes.due_at.toISOString() : ''} />
    </div>
  )
}

function SerializedRemovedNote ({ id, index, paramBase }) {
  const prefix = `${paramBase}[${index + 1}]`
  const name = (field) => `${prefix}[${field}]`

  return (
    <div>
      <input type='hidden' name={name('id')} value={id} />
      <input type='hidden' name={name('_destroy')} value='1' />
    </div>
  )
}

function Serialized ({ notesFields }) {
  const { notes, removedIds, paramBase } = notesFields

  let i = -1
  const index = () => { i++; return i }

  return (
    <div hidden>
      {notes.map((note) => (
        <SerializedNote
          key={note.uniqueId}
          note={note}
          index={index()}
          paramBase={paramBase}
        />
      ))}

      {removedIds.map((id) => (
        <SerializedRemovedNote
          id={id}
          key={id}
          index={index()}
          paramBase={paramBase}
        />
      ))}
    </div>
  )
}

export default Serialized
