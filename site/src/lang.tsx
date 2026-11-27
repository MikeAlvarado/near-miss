import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'

export type Lang = 'es' | 'en'

function initial(): Lang {
  try {
    const saved = localStorage.getItem('lang')
    if (saved === 'es' || saved === 'en') return saved
  } catch {
    // Storage can be blocked; the browser language decides then.
  }
  return navigator.language.toLowerCase().startsWith('es') ? 'es' : 'en'
}

const LangContext = createContext<{ lang: Lang; setLang: (lang: Lang) => void }>({ lang: 'en', setLang: () => {} })

export function LangProvider({ children }: { children: ReactNode }) {
  const [lang, setLang] = useState<Lang>(initial)
  useEffect(() => {
    document.documentElement.lang = lang
    try {
      localStorage.setItem('lang', lang)
    } catch {
      // Nothing to do: the choice lasts for this visit.
    }
  }, [lang])
  return <LangContext.Provider value={{ lang, setLang }}>{children}</LangContext.Provider>
}

export const useLang = () => useContext(LangContext)

/** ES / EN switch. The title of the page stays in English either way. */
export function LangToggle() {
  const { lang, setLang } = useLang()
  return (
    <div className="lang" role="group" aria-label={lang === 'es' ? 'Idioma' : 'Language'}>
      {(['es', 'en'] as const).map((code) => (
        <button key={code} type="button" aria-pressed={lang === code} onClick={() => setLang(code)}>
          {code.toUpperCase()}
        </button>
      ))}
    </div>
  )
}
