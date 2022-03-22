import React from 'react'

import DueDate from './DueDate'

export default function Table ({
  notesForTable,
  editNote,
  removeNote,
  toggleClosedAt,
  currentlyEditting,
  currentlyEdittingUniqueId,
  changeDueDate
}) {
  return (
    <div className='f-c-r-notes-fields-app-table'>
      {notesForTable.map((note) => (
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
              onClick={() => editNote(note)}
            />

            {currentlyEditting ? null : (
              <React.Fragment>
                <DueDate
                  className='f-c-r-notes-fields-app-table__action mr-2'
                  dueAt={note.attributes.due_at}
                  onChange={(dueAt) => changeDueDate(note, dueAt)}
                />

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
