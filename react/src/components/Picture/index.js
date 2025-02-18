import React from 'react'

export function RawPicture ({ src, webpSrc, className, imageClassName, alt, imageStyle, loading }) {
  if (webpSrc) {
    return (
      <picture className={className}>
        <source
          srcSet={webpSrc}
          type='image/webp'
        />
        <img
          src={src}
          className={imageClassName}
          alt={alt || ''}
          style={imageStyle}
          loading={loading}
        />
      </picture>
    )
  } else {
    return (
      <img
        src={src}
        className={imageClassName}
        alt={alt || ''}
        style={imageStyle}
        loading={loading}
      />
    )
  }
}

export default function Picture ({ file, className, alt, imageStyle, imageClassName, lazyload }) {
  const rawPicture = RawPicture({
    src: file.attributes.thumb || file.attributes.dataThumbnail,
    webpSrc: file.attributes.webp_thumb,
    loading: lazyload ? 'lazy' : 'eager',
    alt,
    className,
    imageClassName,
    imageStyle
  })

  return rawPicture
}
