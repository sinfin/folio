import React, { useState, useRef, useEffect, useCallback } from 'react'
import { components } from 'react-select'
import FolioUiIcon from 'components/FolioUiIcon'

const ACTION_AREA_ATTR = 'data-owa-action'

function isActionAreaClick (e) {
  return e.target.closest && e.target.closest(`[${ACTION_AREA_ATTR}]`)
}

function OptionWithActions (props) {
  const { data, selectProps, innerProps } = props
  const [menuOpen, setMenuOpen] = useState(false)
  const [renaming, setRenaming] = useState(false)
  const [renameValue, setRenameValue] = useState(data.label || '')
  const inputRef = useRef(null)
  const menuRef = useRef(null)
  const dotsRef = useRef(null)

  const isNew = data.__isNew__

  useEffect(() => {
    if (renaming && inputRef.current) inputRef.current.focus()
  }, [renaming])

  useEffect(() => {
    if (!menuOpen) return

    const handleClickOutside = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target) &&
          dotsRef.current && !dotsRef.current.contains(e.target)) {
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
    if (e) {
      e.preventDefault()
      e.stopPropagation()
    }
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

  // Create option — green + icon style
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

  // Rename mode — replace the entire option with an input
  if (renaming) {
    return (
      <div className='f-c-r-select-option-rename'>
        <input
          ref={inputRef}
          className='f-c-r-select-option-rename__input'
          value={renameValue}
          onChange={(e) => setRenameValue(e.target.value)}
          onKeyDown={onRenameKeyDown}
          onBlur={() => onRenameSubmit(null)}
          onClick={(e) => e.stopPropagation()}
          onMouseDown={(e) => e.stopPropagation()}
        />
      </div>
    )
  }

  // Override innerProps to prevent react-select from selecting/closing
  // when clicking on the action area (dots button, sub-menu)
  const wrappedInnerProps = {
    ...innerProps,
    onClick: (e) => {
      if (isActionAreaClick(e)) return
      innerProps.onClick && innerProps.onClick(e)
    },
    onMouseDown: (e) => {
      if (isActionAreaClick(e)) return
      innerProps.onMouseDown && innerProps.onMouseDown(e)
    },
    onMouseUp: (e) => {
      if (isActionAreaClick(e)) return
      innerProps.onMouseUp && innerProps.onMouseUp(e)
    }
  }

  return (
    <components.Option {...props} innerProps={wrappedInnerProps}>
      <div className='f-c-r-select-option-with-actions'>
        <span className='f-c-r-select-option-with-actions__label'>
          {props.children}
        </span>
        <span
          className='f-c-r-select-option-with-actions__dots'
          ref={dotsRef}
          onClick={onDotsClick}
          data-owa-action='true'
        >
          <FolioUiIcon name='dots_vertical' height={16} />
        </span>

        {menuOpen && (
          <div
            className='f-c-r-select-option-with-actions__menu'
            ref={menuRef}
            data-owa-action='true'
          >
            <div
              className='f-c-r-select-option-with-actions__menu-item'
              onClick={onRenameClick}
            >
              <FolioUiIcon name='edit_box' height={14} />
              <span>{window.FolioConsole.translations.rename || 'Rename'}</span>
            </div>
            <div
              className='f-c-r-select-option-with-actions__menu-item f-c-r-select-option-with-actions__menu-item--danger'
              onClick={onDeleteClick}
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
