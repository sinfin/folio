import React, { useState, useRef, useEffect } from 'react'
import { makeConfirmed } from 'utils/confirmed'

import FolioUiIcon from 'components/FolioUiIcon'

function isDuplicateLabel (value, currentLabel, existingLabels, loadedOptions) {
  if (!value.trim()) return false
  const normalized = value.trim().toLowerCase()
  if (normalized === (currentLabel || '').toLowerCase()) return false
  if (existingLabels && existingLabels.some((label) => label.toLowerCase().trim() === normalized)) return true
  if (loadedOptions && loadedOptions.some((o) => o.label && o.label.toLowerCase().trim() === normalized)) return true
  return false
}

function Item ({ path, node, remove, onRename, existingLabels, loadedOptions }) {
  const [isEditing, setIsEditing] = useState(false)
  const [editValue, setEditValue] = useState('')
  const inputRef = useRef(null)

  useEffect(() => {
    if (isEditing && inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [isEditing])

  const isDuplicate = isEditing && isDuplicateLabel(editValue, node.label, existingLabels, loadedOptions)

  const onRenameClick = (e) => {
    e.preventDefault()
    e.stopPropagation()
    setEditValue(node.label || '')
    setIsEditing(true)
  }

  const onCancel = () => setIsEditing(false)

  const onSubmit = () => {
    const trimmed = editValue.trim()
    if (!trimmed || isDuplicateLabel(trimmed, node.label, existingLabels, loadedOptions)) return
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
          <button
            type='button'
            className='btn btn-none p-0'
            onMouseDown={(e) => { e.preventDefault(); onSubmit() }}
          >
            <FolioUiIcon name='check' height={16} />
          </button>
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
