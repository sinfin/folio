export default function preventEnterSubmit (e) {
  if (e.key === 'Enter') e.preventDefault()
}
