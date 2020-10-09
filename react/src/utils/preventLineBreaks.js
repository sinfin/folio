export default function preventEnterSubmit (e) {
  if (e.key === 'Enter' && !e.ctrlKey && e.target.tagName === 'TEXTAREA') e.preventDefault()
}
