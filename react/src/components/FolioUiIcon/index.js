import React from 'react'

export default function FolioUiIcon (props) {
  const { name, ...options } = props
  const data = window.Folio.Ui.Icon.data(name, options)

  return (
    <svg
      className={data.classNames.join(' ')}
      style={data.style}
      viewBox={data.viewBox}
      onClick={props.onClick}
    >
      <use xlinkHref={data.href} />
    </svg>
  )
}
