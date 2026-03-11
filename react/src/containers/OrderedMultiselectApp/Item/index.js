import React, { useState, useRef, useEffect } from 'react'
import { makeConfirmed } from 'utils/confirmed'

import FolioUiIcon from 'components/FolioUiIcon'

function isDuplicateLabel (value, currentLabel, existingLabels) {
  if (!existingLabels || !value.trim()) return false
  const normalized = value.trim().toLowerCase()
  if (normalized === (currentLabel || '').toLowerCase()) return false
  return existingLabels.some((label) => label.toLowerCase().trim() === normalized)
}

function Item ({ path, node, remove, onRename, existingLabels }) {
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState('')
  const inputRef = useRef(null)

  useEffect(() => {
    if (isEditing && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [isEditing])

  const isDuplicate = isEditing && isDuplicateLabel(editValue, node.label, existingLabels)

  const onRenameClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setEditValue(node.label || '')
    setIsEditing(true)
  }

  const onCancel = () => setIsEditing(false)

  const onSubmit = () => {
    const trimmed = editValue.trim()
    if (!trimmed || isDuplicateLabel(trimmed, node.label, existingLabels)) return
    if (trimmed !== node.label) {
      onRename && onRename(node, trimmed)
    }
    setIsEditing(false)
  }

  const onKeyDown = (e) => {
    if (e.key === 'Enter') { e.preventDefault(); onSubmit() }
    if (e.key === 'Escape') { e.preventDefault(); onCancel() }
  }

  return (
    <div className='f-c-r-ordered-multiselect-app__item'>
      {isEditing ? (
        <div className='f-c-r-ordered-multiselect-app__item-edit'>
          <input
            ref={inputRef}
            className={`f-c-r-ordered-multiselect-app__item-rename-input${isDuplicate ? ' is-invalid' : ''}`}
            value={editValue}
            onChange={(e) => setEditValue(e.target.value)}
            onKeyDown={onKeyDown}
            onBlur={onCancel}
            title={isDuplicate ? (window.FolioConsole.translations.alreadyExists || 'Already exists') : undefined}
          />
          <span
            className='f-c-r-ordered-multiselect-app__item-action'
            onMouseDown={(e) => { e.preventDefault(); onSubmit() }}
          >
            <FolioUiIcon name='check' height={16} />
          </span>
        </div>
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
