export default function fileKeyToType (fileType) {
  return fileType === 'documents' ? 'Folio::Document' : 'Folio::Image'
}
