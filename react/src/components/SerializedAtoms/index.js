import React from 'react'

function SerializedAtom ({ atom, index, namespace, position }) {
  const prefix = `${namespace}[${index + 1}]`
  const { data, id, meta, type } = atom

  return (
    <div>
      {id && <input type='hidden' name={`${prefix}[id]`} value={id} />}
      <input type='hidden' name={`${prefix}[position]`} value={index} />
      <input type='hidden' name={`${prefix}[type]`} value={type} />
      {Object.keys(meta.structure).map((key) => (
        <input key={key} type='hidden' name={`${prefix}[${key}]`} value={data[key]} />
      ))}
      {meta.attachments.map((attachmentType) => {
        const key = `${attachmentType.type}_attributes`
        const values = atom[key]
        if (!values) return null
        return (
          attachmentType.plural ? null : (
            <React.Fragment key={attachmentType.type}>
              {values['_destroy'] ? (<input type='hidden' name={`${prefix}[${key}][_destroy]`} value='1' />) : (
                <React.Fragment>
                  <input type='hidden' name={`${prefix}[${key}][file_id]`} value={values['file_id']} />
                  <input type='hidden' name={`${prefix}[${key}][alt]`} value={values['alt'] || ''} />
                  <input type='hidden' name={`${prefix}[${key}][title]`} value={values['title'] || ''} />
                </React.Fragment>
              )}
            </React.Fragment>
          )
        )
      })}
    </div>
  )
}

function SerializedAtoms ({ atoms, destroyedIds, namespace }) {
  return (
    <div hidden>
      {atoms.map((atom, index) => {
        return (
          <SerializedAtom
            key={atom.id || atom.timestamp}
            atom={atom}
            index={index}
            namespace={namespace}
          />
        )
      })}

      {destroyedIds.map((id, i) => (
        <React.Fragment key={id}>
          <input type='hidden' name={`${namespace}[${1000000 + i}][id]`} value={id} />
          <input type='hidden' name={`${namespace}[${1000000 + i}][_destroy]`} value='1' />
        </React.Fragment>
      ))}
    </div>
  )
}

export { SerializedAtom }
export default SerializedAtoms
