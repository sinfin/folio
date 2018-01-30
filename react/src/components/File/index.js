import React from 'react'
import styled from 'styled-components'

import ThumbOrInfo from './ThumbOrInfo'

const OuterWrap = styled.div`
  width: 150px;
  height: 150px;
  position: relative;
  display: inline-block;
  margin: 15px;
`

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

const IconsWrap = styled.div`
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 2;
  background: rgba(255, 255, 255, 0.75);
  padding: 10px;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  font-size: 30px;
  opacity: ${(props) => props.visible ? 1 : 0};

  ${(props) => props.pointer ? 'cursor: pointer !important;' : 'i { cursor: pointer !important; }'}

  &:hover {
    opacity: 1;
  }
`

export function File ({ file, selected, position, onClick, singleSelect }) {
  const inputPrefix = `node[file_placements_attributes][${file.file_id}]`

  return (
    <OuterWrap onClick={selected ? null : onClick}>
      <input type='hidden' name={`${inputPrefix}[id]`} value={file.id} />
      <input type='hidden' name={`${inputPrefix}[file_id]`} value={file.file_id} />
      <input type='hidden' name={`${inputPrefix}[position]`} value={position} />
      <input type='hidden' name={`${inputPrefix}[_destroy]`} value={selected ? 0 : 1} />

      <ImageWrap background={file.dominant_color}>
        <ThumbOrInfo file={file} singleSelect={singleSelect} />
      </ImageWrap>

      <IconsWrap pointer={!selected}>
        {selected ? (
          <i className='fa fa-times-circle text-danger' onClick={onClick}></i>
        ) : (
          singleSelect ? (
            <i className='fa fa-check-circle text-primary'></i>
          ) : (
            <i className='fa fa-arrow-circle-up text-success'></i>
          )
        )}
      </IconsWrap>
    </OuterWrap>
  )
}

export function UploadingFile ({ upload }) {
  return (
    <OuterWrap>
      <ImageWrap>
        {upload.thumb && <img src={upload.thumb} alt='' />}
      </ImageWrap>

      <IconsWrap visible>
        <i className='fa fa-upload folio-console-animation-pulsing'></i>
      </IconsWrap>
    </OuterWrap>
  )
}

export function DropzoneTrigger ({ upload }) {
  return (
    <OuterWrap className='folio-console-dropzone-trigger bg-secondary'>
      <IconsWrap visible pointer>
        <i className='fa fa-plus-circle'></i>
      </IconsWrap>
    </OuterWrap>
  )
}

export default File
