import React from 'react'
import styled from 'styled-components'

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
  align-items: center;
  justify-content: center;
  font-size: 30px;
  cursor: pointer;
  opacity: ${(props) => props.visible ? 1 : 0};

  &:hover {
    opacity: 1;
  }
`

export function File ({ file, selected, position, onClick }) {
  const inputPrefix = `node[file_placements_attributes][${file.file_id}]`

  return (
    <OuterWrap onClick={onClick}>
      <input type='hidden' name={`${inputPrefix}[id]`} value={file.id} />
      <input type='hidden' name={`${inputPrefix}[file_id]`} value={file.file_id} />
      <input type='hidden' name={`${inputPrefix}[position]`} value={position} />
      <input type='hidden' name={`${inputPrefix}[_destroy]`} value={selected ? 0 : 1} />

      <ImageWrap>
        {file.thumb && <img src={file.thumb} alt={file.file_name} />}
      </ImageWrap>

      <IconsWrap>
        {selected ? (
          <i className='fa fa-arrow-circle-down text-danger'></i>
        ) : (
          <i className='fa fa-arrow-circle-up text-success'></i>
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
        <i className='fa fa-upload'></i>
      </IconsWrap>
    </OuterWrap>
  )
}

export default File
