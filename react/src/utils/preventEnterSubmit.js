export default function preventEnterSubmit (e) {
  if (e.key === 'Enter' && e.target.tagName === 'INPUT') e.preventDefault()
}
