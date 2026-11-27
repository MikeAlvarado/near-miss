import { useId, useState, type FormEvent } from 'react'
import { useLang } from './lang'
import { WAITLIST } from './site'

const copy = {
  es: {
    label: 'Tu correo',
    placeholder: 'tu@correo.com',
    button: 'Avísame',
    note: 'Un solo correo, el día que salga.',
    done: 'Listo. Te avisamos cuando salga.',
    error: 'No se pudo guardar. Intenta de nuevo.',
  },
  en: {
    label: 'Your email',
    placeholder: 'you@email.com',
    button: 'Notify me',
    note: 'One email, the day it launches.',
    done: "Done. We'll let you know when it's out.",
    error: 'That did not go through. Try again.',
  },
}

/** One field: leave your email to hear when the app is out. */
export function Waitlist() {
  const { lang } = useLang()
  const t = copy[lang]
  const id = useId()
  const [email, setEmail] = useState('')
  const [state, setState] = useState<'idle' | 'sending' | 'done' | 'error'>('idle')

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    if (!WAITLIST.action) {
      setState('error')
      return
    }
    setState('sending')
    try {
      const body = new FormData()
      body.append(WAITLIST.field, email.trim())
      body.append(WAITLIST.langField, lang)
      // The form answers from another origin, so the reply cannot be read: no error means it was sent.
      await fetch(WAITLIST.action, { method: 'POST', mode: 'no-cors', body })
      setState('done')
    } catch {
      setState('error')
    }
  }

  if (state === 'done') {
    return (
      <p className="waitlist-done" role="status">
        <span aria-hidden>✓</span> {t.done}
      </p>
    )
  }

  return (
    <form className="waitlist" onSubmit={submit}>
      <div className="waitlist-field">
        <label className="sr-only" htmlFor={id}>{t.label}</label>
        <input
          id={id}
          type="email"
          name="email"
          required
          autoComplete="email"
          inputMode="email"
          placeholder={t.placeholder}
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
        <button type="submit" disabled={state === 'sending'}>{t.button}</button>
      </div>
      <p className="waitlist-note" role={state === 'error' ? 'alert' : undefined}>
        {state === 'error' ? t.error : t.note}
      </p>
    </form>
  )
}
