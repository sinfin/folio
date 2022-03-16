import React from 'react'

export default function Table ({
  notes,
  editNote,
  removeNote,
  toggleClosedAt,
  currentlyEditting,
  currentlyEdittingUniqueId
}) {
  return (
    <div className='f-c-r-notes-fields-app-table'>
      {notes.map((note) => (
        currentlyEdittingUniqueId && currentlyEdittingUniqueId === note.uniqueId ? null : (
          <div className='f-c-r-notes-fields-app-table__row' key={note.uniqueId}>
            <input
              type='checkbox'
              className='f-c-r-notes-fields-app-table__checkbox mr-3'
              checked={note.attributes.closed_at !== null}
              onChange={() => toggleClosedAt(note)}
            />

            <div
              className='f-c-r-notes-fields-app-table__content mr-3'
              dangerouslySetInnerHTML={{ __html: note.attributes.content.replace(/\n/g, '<br>') }}
            />

            {currentlyEditting ? null : (
              <React.Fragment>
                <span className='f-c-r-notes-fields-app-table__action fa fa--12 fa-edit mr-2' onClick={() => editNote(note)} />

                <span className='f-c-r-notes-fields-app-table__action fa fa-times text-danger' onClick={() => removeNote(note)} />
              </React.Fragment>
            )}
          </div>
        )
      ))}
    </div>
  )
}
