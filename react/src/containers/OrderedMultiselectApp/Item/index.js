import React, { useState, useCallback } from 'react'
import { makeConfirmed } from 'utils/confirmed'

import FolioUiIcon from 'components/FolioUiIcon'
import InlineRenameInput from 'components/InlineRenameInput'

function Item ({ path, node, remove, onRename, existingLabels, loadedOptions }) {
  const [isEditing, setIsEditing] = useState(false)

  const onRenameClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setIsEditing(true)
  }

  const onCancel = useCallback(() => setIsEditing(false), [])

  const onSubmit = useCallback((newLabel) => {
    onRename && onRename(node, newLabel)
  }, [onRename, node])

  return (
    <div className='f-c-r-ordered-multiselect-app__item'>
      {isEditing ? (
        <div className='f-c-r-ordered-multiselect-app__item-edit'>
          <InlineRenameInput
            currentLabel={node.label || ''}
            onSubmit={onSubmit}
            onCancel={onCancel}
            existingLabels={existingLabels}
            loadedOptions={loadedOptions}
            className='f-c-r-ordered-multiselect-app__item-rename-input'
          />
        </div>
      ) : (
        <>
          <span className='f-c-r-ordered-multiselect-app__item-label'>{node.label}</span>
          {onRename && (
            <button type='button' className='btn btn-none p-0' onClick={onRenameClick}>
              <FolioUiIcon name='edit_box' height={16} />
            </button>
          )}
        </>
      )}

      <button
        type='button'
        className='btn btn-none p-0 text-danger'
        onClick={makeConfirmed(() => remove(node))}
      >
        <FolioUiIcon name='delete' height={16} />
      </button>
    </div>
  )
}

export default Item
