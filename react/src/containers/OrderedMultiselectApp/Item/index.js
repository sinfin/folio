import React, { useState, useRef, useEffect } from 'react'
import { makeConfirmed } from 'utils/confirmed'

import FolioUiIcon from 'components/FolioUiIcon'

function Item ({ path, node, remove, onRename }) {
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState('')
  const inputRef = useRef(null)

  useEffect(() => {
    if (isEditing && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [isEditing])

  const onRenameClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setEditValue(node.label || '')
    setIsEditing(true)
  }

  const onSubmit = () => {
    const trimmed = editValue.trim()
    if (trimmed && trimmed !== node.label) {
      onRename && onRename(node, trimmed)
    }
    setIsEditing(false)
  }

  const onKeyDown = (e) => {
    if (e.key === 'Enter') { e.preventDefault(); onSubmit() }
    if (e.key === 'Escape') { e.preventDefault(); setIsEditing(false) }
  }

  return (
    <div className='f-c-r-ordered-multiselect-app__item'>
      {isEditing ? (
        <input
          ref={inputRef}
          className='f-c-r-ordered-multiselect-app__item-rename-input'
          value={editValue}
          onChange={(e) => setEditValue(e.target.value)}
          onKeyDown={onKeyDown}
          onBlur={onSubmit}
        />
      ) : (
        <>
          <span className='f-c-r-ordered-multiselect-app__item-label'>{node.label}</span>
          {onRename && (
            <FolioUiIcon
              class='f-c-r-ordered-multiselect-app__item-action'
              name='edit_box'
              height={16}
              onClick={onRenameClick}
            />
          )}
        </>
      )}

      <FolioUiIcon
        class='text-danger f-c-r-ordered-multiselect-app__item-action f-c-r-ordered-multiselect-app__item-destroy'
        name='delete'
        height={16}
        onClick={makeConfirmed(() => remove(node))}
      />
    </div>
  )
}

export default Item
