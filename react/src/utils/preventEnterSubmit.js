export default function preventEnterSubmit (e) {
  if (e.key === 'Enter' && !e.ctrlKey && e.target.tagName === 'INPUT') e.preventDefault()
}
