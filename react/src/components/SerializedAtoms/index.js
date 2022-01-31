import React from 'react'

function SerializedAttachment ({ prefix, attachmentKey, attachment, index, showId }) {
  let name = (field) => `${prefix}[${attachmentKey}][${field}]`
  if (typeof index !== 'undefined') {
    name = (field) => `${prefix}[${attachmentKey}][${index}][${field}]`
  }

  return (
    <React.Fragment>
      {showId && <input type='hidden' name={name('id')} value={attachment['id'] || ''} />}
      {attachment['_destroy'] ? (
        <input type='hidden' name={name('_destroy')} value='1' />
      ) : (
        <React.Fragment>
          {(index || index === 0) ? <input type='hidden' name={name('position')} value={index + 1} /> : null}
          <input type='hidden' name={name('file_id')} value={attachment['file_id']} />
          <input type='hidden' name={name('alt')} value={attachment['alt'] || ''} />
          <input type='hidden' name={name('title')} value={attachment['title'] || ''} />
        </React.Fragment>
      )}
    </React.Fragment>
  )
}

function SerializedAttachments ({ atom, prefix }) {
  return (
    <React.Fragment>
      {atom.meta.attachments.map(({ plural, key }) => {
        const values = atom[key]
        if (!values) return null
        return (
          plural ? (
            values.map((value, i) => (
              <SerializedAttachment
                prefix={prefix}
                attachmentKey={key}
                attachment={value}
                index={i}
                key={`${value.id || 'nil'}-${value.file_id}`}
                showId={Boolean(atom.id)}
              />
            ))
          ) : (
            <SerializedAttachment
              prefix={prefix}
              attachmentKey={key}
              attachment={values}
              key={key}
              showId={Boolean(values.id)}
            />
          )
        )
      })}
    </React.Fragment>
  )
}

function SerializedAssociations ({ atom, prefix }) {
  return (
    <React.Fragment>
      {Object.keys(atom.meta.associations).map((key) => {
        const record = atom.associations[key]
        let id, type

        if (record) {
          id = record.id
          type = record.type
        } else {
          id = ''
          type = ''
        }

        return (
          <React.Fragment key={key}>
            <input type='hidden' name={`${prefix}[${key}][id]`} value={id} />
            <input type='hidden' name={`${prefix}[${key}][type]`} value={type} />
          </React.Fragment>
        )
      })}
    </React.Fragment>
  )
}

function SerializedAtom ({ atom, index, namespace, position }) {
  const prefix = `${namespace}[${index + 1}]`
  const { data, id, meta, type } = atom

  return (
    <div>
      {id && <input type='hidden' name={`${prefix}[id]`} value={id} />}
      <input type='hidden' name={`${prefix}[position]`} value={index} />
      <input type='hidden' name={`${prefix}[type]`} value={type} />
      {Object.keys(meta.structure).map((key) => (
        <input key={key} type='hidden' name={`${prefix}[${key}]`} value={data[key] || ''} />
      ))}
      <SerializedAttachments atom={atom} prefix={prefix} />
      <SerializedAssociations atom={atom} prefix={prefix} />
    </div>
  )
}

function SerializedAtoms ({ atoms, destroyedIds, namespace }) {
  return (
    <div hidden className='f-c-simple-form-with-atoms__dirty-wrap'>
      {atoms.map((atom, index) => {
        return (
          <SerializedAtom
            key={atom.id || atom.lodashId}
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
