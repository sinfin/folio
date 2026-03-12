import React, { useState, useRef, useEffect, useCallback, useMemo } from 'react'
import FolioUiIcon from 'components/FolioUiIcon'
import isDuplicateLabel from 'utils/isDuplicateLabel'

function InlineRenameInput ({ currentLabel, onSubmit, onCancel, existingLabels, loadedOptions, className }) {
  const [editValue, setEditValue] = useState(currentLabel || '')
  const inputRef = useRef(null)

  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.focus()
      inputRef.current.select()
    }
  }, [])

  const isDuplicate = useMemo(() => {
    return isDuplicateLabel(editValue, currentLabel, existingLabels, loadedOptions)
  }, [editValue, currentLabel, existingLabels, loadedOptions])

  const handleSubmit = useCallback(() => {
    const trimmed = editValue.trim()
    if (!trimmed || isDuplicateLabel(trimmed, currentLabel, existingLabels, loadedOptions)) {
      onCancel()
      return
    }
    if (trimmed !== currentLabel) {
      onSubmit(trimmed)
    }
    onCancel()
  }, [editValue, currentLabel, existingLabels, loadedOptions, onSubmit, onCancel])

  const onKeyDown = useCallback((e) => {
    e.stopPropagation()
    if (e.key === 'Enter') { e.preventDefault(); handleSubmit() }
    if (e.key === 'Escape') { e.preventDefault(); onCancel() }
  }, [handleSubmit, onCancel])

  return (
    <>
      <input
        ref={inputRef}
        className={`${className || ''}${isDuplicate ? ' is-invalid' : ''}`}
        value={editValue}
        onChange={(e) => setEditValue(e.target.value)}
        onKeyDown={onKeyDown}
        onBlur={onCancel}
        onMouseDown={(e) => e.stopPropagation()}
        title={isDuplicate ? (window.FolioConsole.translations.alreadyExists || 'Already exists') : undefined}
      />
      <button
        type='button'
        className='btn btn-none p-0'
        onMouseDown={(e) => { e.preventDefault(); handleSubmit() }}
        title={window.FolioConsole.translations.rename || 'Confirm'}
      >
        <FolioUiIcon name='check' height={16} />
      </button>
    </>
  )
}

export default InlineRenameInput
