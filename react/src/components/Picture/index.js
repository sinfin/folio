import React from 'react'

export function RawPicture ({ src, webpSrc, className, imageClassName, alt, imageStyle }) {
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
      />
    )
  }
}

export default function Picture ({ file, className, alt, imageStyle, imageClassName }) {
  return RawPicture({
    src: file.attributes.thumb,
    webpSrc: file.attributes.webp_thumb,
    alt,
    className,
    imageClassName,
    imageStyle
  })
}
