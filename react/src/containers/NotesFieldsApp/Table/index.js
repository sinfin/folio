import React from 'react'

export default function Table ({ notes }) {
  return (
    <div className='f-c-r-notes-fields-app-table'>
      {notes.map((note) => (
        <div className='f-c-r-notes-fields-app-table__row' key={note.uniqueId}>
          <div
            className='f-c-r-notes-fields-app-table__content'
            dangerouslySetInnerHTML={{ __html: note.attributes.content.replace(/\n/g, '<br>') }}
          />
        </div>
      ))}
    </div>
  )
}
