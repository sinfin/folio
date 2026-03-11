import React, { useState, useRef, useEffect, useCallback } from 'react'
import { components } from 'react-select'
import FolioUiIcon from 'components/FolioUiIcon'

function OptionWithActions (props) {
  const { data, selectProps } = props
  const [menuOpen, setMenuOpen] = useState(false)
  const [renaming, setRenaming] = useState(false)
  const [renameValue, setRenameValue] = useState(data.label || '')
  const inputRef = useRef(null)
  const menuRef = useRef(null)

  const isNew = data.__isNew__

  useEffect(() => {
    if (renaming && inputRef.current) inputRef.current.focus()
  }, [renaming])

  // Close sub-menu when clicking outside
  useEffect(() => {
    if (!menuOpen) return

    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) {
        setMenuOpen(false)
      }
    }

    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [menuOpen])

  const onDotsClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    setMenuOpen((prev) => !prev)
  }, [])

  const onRenameClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    setRenaming(true)
    setRenameValue(data.label || '')
    setMenuOpen(false)
  }, [data.label])

  const onRenameSubmit = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    const trimmed = renameValue.trim()
    if (trimmed && trimmed !== data.label) {
      selectProps.onRenameOption && selectProps.onRenameOption(data, trimmed)
    }
    setRenaming(false)
  }, [renameValue, data, selectProps])

  const onRenameKeyDown = useCallback((e) => {
    e.stopPropagation()
    if (e.key === 'Enter') onRenameSubmit(e)
    if (e.key === 'Escape') {
      e.preventDefault()
      setRenaming(false)
      setRenameValue(data.label || '')
    }
  }, [onRenameSubmit, data.label])

  const onDeleteClick = useCallback((e) => {
    e.preventDefault()
    e.stopPropagation()
    setMenuOpen(false)
    selectProps.onDeleteOption && selectProps.onDeleteOption(data)
  }, [selectProps, data])

  // Newly created items — green + icon style
  if (isNew) {
    return (
      <components.Option {...props}>
        <span className='f-c-r-select-create-option'>
          <span className='f-c-r-select-create-option__icon'>+</span>
          {props.children}
        </span>
      </components.Option>
    )
  }

  if (renaming) {
    return (
      <div className='f-c-r-select-option-rename' onClick={(e) => e.stopPropagation()}>
        <input
          ref={inputRef}
          className='f-c-r-select-option-rename__input'
          value={renameValue}
          onChange={(e) => setRenameValue(e.target.value)}
          onKeyDown={onRenameKeyDown}
          onBlur={onRenameSubmit}
          onMouseDown={(e) => e.stopPropagation()}
        />
      </div>
    )
  }

  return (
    <components.Option {...props}>
      <div className='f-c-r-select-option-with-actions'>
        <span className='f-c-r-select-option-with-actions__label'>
          {props.children}
        </span>
        <span
          className='f-c-r-select-option-with-actions__dots'
          onClick={onDotsClick}
          onMouseDown={(e) => e.stopPropagation()}
        >
          <FolioUiIcon name='dots_vertical' height={16} />
        </span>

        {menuOpen && (
          <div className='f-c-r-select-option-with-actions__menu' ref={menuRef}>
            <div
              className='f-c-r-select-option-with-actions__menu-item'
              onClick={onRenameClick}
              onMouseDown={(e) => e.stopPropagation()}
            >
              <FolioUiIcon name='edit_box' height={14} />
              <span>{window.FolioConsole.translations.rename || 'Rename'}</span>
            </div>
            <div
              className='f-c-r-select-option-with-actions__menu-item f-c-r-select-option-with-actions__menu-item--danger'
              onClick={onDeleteClick}
              onMouseDown={(e) => e.stopPropagation()}
            >
              <FolioUiIcon name='delete' height={14} />
              <span>{window.FolioConsole.translations.deleteFromDb || 'Delete'}</span>
            </div>
          </div>
        )}
      </div>
    </components.Option>
  )
}

export default OptionWithActions
