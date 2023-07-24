import React from 'react'

export default function FolioUiIcon (props) {
  const { name, ...options } = props
  const data = window.Folio.Ui.Icon.data(name, options)

  const dataProps = {}

  Object.keys(data.data).forEach((key) => {
    dataProps[`data-${key}`] = data.data[key]
  })

  return (
    <svg
      className={data.classNames.join(' ')}
      style={data.style}
      viewBox={data.viewBox}
      onClick={props.onClick}
      {...dataProps}
    >
      <use xlinkHref={data.href} />
    </svg>
  )
}
