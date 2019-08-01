export default function fileTypeToKey (fileType) {
  return fileType === 'Folio::Document' ? 'documents' : 'images'
}
