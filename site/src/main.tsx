import '@fontsource-variable/mona-sans'
import '@fontsource/instrument-serif'
import '@fontsource/instrument-serif/400-italic.css'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
import { LangProvider } from './lang'
import { Privacy } from './Privacy'
import './styles.css'

const root = document.getElementById('root')!
createRoot(root).render(
  <StrictMode>
    <LangProvider>{root.dataset.page === 'privacy' ? <Privacy /> : <App />}</LangProvider>
  </StrictMode>,
)
