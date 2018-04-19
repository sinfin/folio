import React from 'react'
import styled from 'styled-components'

import ThumbOrInfo from './ThumbOrInfo'

const OUTER_STYLE = `
  width: 150px;
  height: 150px;
  position: relative;
  display: inline-block;
  margin: 15px;
`

const OuterWrap = styled.div`${OUTER_STYLE}`
const OuterLinkWrap = styled.a`${OUTER_STYLE}`

const ImageWrap = styled.div`
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1;
  ${(props) => props.background ? `background: ${props.background};` : ''}

  img {
    width: 100%;
    max-height: 100%;
    display: block;
  }
`

export function File ({ attachmentable, file, selected, position, onClick, singleSelect }) {
  const inputPrefix = `${attachmentable || 'node'}[file_placements_attributes][]`
  const disabled = !selected && !file.id

  return (
    <OuterWrap onClick={selected ? null : onClick}>
      {file.id && <input type='hidden' name={`${inputPrefix}[id]`} value={file.id} />}
      <input disabled={disabled} type='hidden' name={`${inputPrefix}[file_id]`} value={file.file_id} />
      <input disabled={disabled} type='hidden' name={`${inputPrefix}[position]`} value={position} />
      <input disabled={disabled} type='hidden' name={`${inputPrefix}[_destroy]`} value={selected ? 0 : 1} />

      <ImageWrap background={file.dominant_color}>
        <ThumbOrInfo file={file} singleSelect={singleSelect} />
      </ImageWrap>

      <div className={`folio-console-hover-destroy ${selected ? 'pointer' : ''}`}>
        {selected ? (
          <i className='fa fa-times-circle' onClick={onClick}></i>
        ) : (
          singleSelect ? (
            <i className='fa fa-check-circle'></i>
          ) : (
            <i className='fa fa-arrow-circle-up'></i>
          )
        )}
      </div>
    </OuterWrap>
  )
}

export function LinkFile ({ file }) {
  return (
    <OuterLinkWrap href={file.edit_path}>
      <ImageWrap background={file.dominant_color}>
        <ThumbOrInfo file={file} />
      </ImageWrap>
    </OuterLinkWrap>
  )
}

export function UploadingFile ({ upload }) {
  return (
    <OuterWrap>
      <ImageWrap>
        {upload.thumb && <img src={upload.thumb} alt='' />}
      </ImageWrap>

      <div className='folio-console-hover-destroy visible'>
        <i className='fa fa-upload folio-console-animation-pulsing'></i>
      </div>
    </OuterWrap>
  )
}

export function DropzoneTrigger ({ upload }) {
  return (
    <OuterWrap className='folio-console-dropzone-trigger bg-secondary'>
      <div className='folio-console-hover-destroy visible pointer'>
        <i className='fa fa-plus-circle'></i>
      </div>
    </OuterWrap>
  )
}

export default File
