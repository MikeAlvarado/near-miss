import '@fontsource-variable/mona-sans'
import '@fontsource/instrument-serif'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
import { Privacy } from './Privacy'
import './styles.css'

const root = document.getElementById('root')!
createRoot(root).render(
  <StrictMode>{root.dataset.page === 'privacy' ? <Privacy /> : <App />}</StrictMode>,
)
