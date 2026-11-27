import { motion, useReducedMotion, useScroll, useTransform, type MotionValue } from 'motion/react'
import { useRef, type ReactNode } from 'react'
import { LangToggle, useLang, type Lang } from './lang'
import { ISSUES, REPO, asset, base } from './site'
import { TrailsCanvas } from './TrailsCanvas'
import { WalkScene } from './WalkScene'

const ease = [0.23, 1, 0.32, 1] as const

type Copy = {
  nav: { how: string; privacy: string; home: string; sections: string }
  eyebrow: string
  lede: string
  soon: string
  code: string
  fine: string
  heroAlt: string
  marquee: string[]
  statement: string
  moment: { label: string; title: ReactNode; lede: string }
  how: { label: string; title: ReactNode }
  steps: { title: string; text: string; alt: string }[]
  privacy: { label: string; title: ReactNode; lede: string; facts: [string, string][]; more: string }
  numbers: [string, string][]
  footer: { license: string; privacy: string; support: string; links: string }
}

const copy: Record<Lang, Copy> = {
  es: {
    nav: { how: 'Cómo funciona', privacy: 'Privacidad', home: 'Near Miss, inicio', sections: 'Secciones' },
    eyebrow: 'Antes de conocerse',
    lede: 'Tus fotos saben dónde estuviste cada día. Las de tu pareja también. Near Miss las compara y pinta en un mapa las veces que estuvieron a unas calles, sin saberlo.',
    soon: 'Pronto en TestFlight',
    code: 'Ver el código',
    fine: 'Para iPhone · Gratis · Tus fotos no salen de tu teléfono',
    heroAlt: 'Near Miss mostrando dos personas a 300 metros en la Alameda, el mismo día',
    marquee: ['a 300 m', 'el mismo día', 'sin saberlo', 'en la misma cuadra', 'a 4 min a pie', 'tres años antes', 'en el mismo concierto', 'a una calle'],
    statement: 'Quizá ya estuvieron en la misma calle, el mismo día, a unos pasos, años antes de saber que el otro existía.',
    moment: {
      label: 'El momento',
      title: <>Baja hasta la calle<br />y los ve <em>caminar</em>.</>,
      lede: 'El mapa se pinta año por año. Al final, la cámara vuela al lugar donde casi se cruzan y cada quien camina sus últimos pasos.',
    },
    how: { label: 'Cómo funciona', title: <>Tres pasos, dos teléfonos,<br />ningún <em>servidor</em>.</> },
    steps: [
      { title: 'Lee tus fotos', text: 'Near Miss toma solo la fecha y el lugar de cada foto. No abre ni copia ninguna imagen.', alt: 'Pantalla de bienvenida de Near Miss con dos rastros de luz' },
      { title: 'Mándense el rastro', text: 'Cada quien genera un archivo pequeño con lugares aproximados y días, y se lo manda al otro por AirDrop o Mensajes.', alt: 'Mapa de México con los dos rastros pintándose en orden' },
      { title: 'Pinta el mapa', text: 'Los dos rastros se dibujan en el orden en que pasaron y la cámara baja hasta la calle donde casi se cruzan.', alt: 'Mapa a nivel de calle con los dos puntos a 300 metros' },
    ],
    privacy: {
      label: 'Privacidad',
      title: <>Nada sale de tu iPhone<br />si tú no lo <em>mandas</em>.</>,
      lede: 'Lo único que viaja es el archivo que tú decides mandarle a tu pareja. Lo demás se queda en el teléfono.',
      facts: [
        ['Servidor', 'Ninguno. No hay nada que hostear ni a dónde subir tus datos.'],
        ['Cuenta', 'No hay registro, correo ni contraseña.'],
        ['Qué lee', 'La fecha y la ubicación de cada foto. Nunca la imagen.'],
        ['Precisión', 'Celdas de unos 150 m y el día. Tu pareja recibe eso, no direcciones exactas.'],
        ['Mapa', 'Es el mapa de Apple: Apple ve qué zona se muestra, no tus fotos ni tus rastros.'],
        ['Código', 'Abierto, con licencia MIT. Puedes leer cada línea.'],
      ],
      more: 'Leer la política de privacidad completa →',
    },
    numbers: [['0', 'servidores'], ['150 m', 'tamaño de cada celda'], ['2', 'teléfonos, nada más'], ['MIT', 'código abierto']],
    footer: { license: 'Licencia MIT', privacy: 'Privacidad', support: 'Soporte', links: 'Enlaces' },
  },
  en: {
    nav: { how: 'How it works', privacy: 'Privacy', home: 'Near Miss, home', sections: 'Sections' },
    eyebrow: 'Before you met',
    lede: "Your photos know where you were every day. So do your partner's. Near Miss compares them and paints on a map the times you were a few streets apart, without knowing it.",
    soon: 'Coming soon to TestFlight',
    code: 'View the code',
    fine: 'For iPhone · Free · Your photos never leave your phone',
    heroAlt: 'Near Miss showing two people 300 meters apart in a park, on the same day',
    marquee: ['300 m away', 'the same day', 'without knowing it', 'on the same block', 'a 4 min walk', 'three years earlier', 'at the same concert', 'one street over'],
    statement: 'Maybe you were already on the same street, on the same day, a few steps apart, years before you knew the other existed.',
    moment: {
      label: 'The moment',
      title: <>It comes down to the street<br />and watches you <em>walk</em>.</>,
      lede: 'The map is painted year by year. At the end, the camera flies to the place where you almost crossed paths and each of you walks your last steps.',
    },
    how: { label: 'How it works', title: <>Three steps, two phones,<br />no <em>server</em>.</> },
    steps: [
      { title: 'It reads your photos', text: 'Near Miss takes only the date and place of each photo. It never opens or copies an image.', alt: 'Near Miss welcome screen with two trails of light' },
      { title: 'Send each other the trail', text: 'Each of you makes a small file with approximate places and days, and sends it to the other over AirDrop or Messages.', alt: 'Map of Mexico with the two trails being painted in order' },
      { title: 'Paint the map', text: 'The two trails are drawn in the order they happened and the camera comes down to the street where you almost crossed paths.', alt: 'Street-level map with the two points 300 meters apart' },
    ],
    privacy: {
      label: 'Privacy',
      title: <>Nothing leaves your iPhone<br />unless you <em>send</em> it.</>,
      lede: 'The only thing that travels is the file you choose to send to your partner. Everything else stays on the phone.',
      facts: [
        ['Server', 'None. There is nothing to host and nowhere to upload your data.'],
        ['Account', 'No sign-up, no email, no password.'],
        ['What it reads', 'The date and location of each photo. Never the image.'],
        ['Precision', 'Cells of about 150 m and the day. Your partner gets that, not exact addresses.'],
        ['Map', "It is Apple's map: Apple sees which area is shown, not your photos or your trails."],
        ['Code', 'Open, under the MIT license. You can read every line.'],
      ],
      more: 'Read the full privacy policy →',
    },
    numbers: [['0', 'servers'], ['150 m', 'size of each cell'], ['2', 'phones, nothing else'], ['MIT', 'open source']],
    footer: { license: 'MIT License', privacy: 'Privacy', support: 'Support', links: 'Links' },
  },
}

const shots = ['welcome', 'painting', 'near-miss']

function Reveal({ text, start = 0, italic }: { text: string; start?: number; italic?: string }) {
  const reduced = useReducedMotion()
  return (
    <span className="line">
      {text.split(' ').map((word, index) => (
        <motion.span
          key={`${word}-${index}`}
          className={word === italic ? 'word italic' : 'word'}
          initial={reduced ? false : { opacity: 0, y: 14, filter: 'blur(12px)' }}
          animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
          transition={{ duration: 0.8, delay: 0.15 + (start + index) * 0.07, ease }}
        >
          {word}{' '}
        </motion.span>
      ))}
    </span>
  )
}

function Rise({ children, delay = 0, className }: { children: ReactNode; delay?: number; className?: string }) {
  const reduced = useReducedMotion()
  return (
    <motion.div
      className={className}
      initial={reduced ? false : { opacity: 0, y: 28 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, amount: 0.25 }}
      transition={{ duration: 0.8, delay, ease }}
    >
      {children}
    </motion.div>
  )
}

function Phone({ shot, alt, className = '' }: { shot: string; alt: string; className?: string }) {
  const { lang } = useLang()
  return (
    <div className={`phone ${className}`}>
      <img src={asset(`shots/${lang}/${shot}.png`)} alt={alt} loading="lazy" decoding="async" />
    </div>
  )
}

function GitHubMark() {
  return (
    <svg viewBox="0 0 16 16" width="16" height="16" aria-hidden fill="currentColor">
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8Z" />
    </svg>
  )
}

function StatementWord({ word, progress, from, to }: { word: string; progress: MotionValue<number>; from: number; to: number }) {
  const opacity = useTransform(progress, [from, to], [0.16, 1])
  return <motion.span style={{ opacity }}>{word} </motion.span>
}

function Statement({ text }: { text: string }) {
  const ref = useRef<HTMLParagraphElement | null>(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start 0.85', 'end 0.45'] })
  const words = text.split(' ')
  return (
    <section className="statement container">
      <p ref={ref} className="display">
        {words.map((word, index) => (
          <StatementWord key={index} word={word} progress={scrollYProgress} from={index / words.length} to={(index + 1) / words.length} />
        ))}
      </p>
    </section>
  )
}

export function App() {
  const { lang } = useLang()
  const t = copy[lang]
  const year = new Date().getFullYear()
  return (
    <>
      <div className="grain" aria-hidden />
      <header className="nav">
        <a className="brand" href={base} aria-label={t.nav.home}>
          <img src={asset('icon.png')} alt="" width="30" height="30" />
          <span>Near Miss</span>
        </a>
        <nav aria-label={t.nav.sections}>
          <a href="#how">{t.nav.how}</a>
          <a href="#privacy">{t.nav.privacy}</a>
          <a href={REPO}><GitHubMark /> GitHub</a>
          <LangToggle />
        </nav>
      </header>

      <main>
        <section className="hero">
          <TrailsCanvas />
          <div className="hero-inner container">
            <div className="hero-copy">
              <motion.p className="label accent" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.8 }}>
                {t.eyebrow}
              </motion.p>
              <h1 className="display" lang="en">
                <Reveal text="You almost" italic="almost" />
                <Reveal text="met." start={2} />
              </h1>
              <motion.p className="lede" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8, delay: 0.55, ease }}>
                {t.lede}
              </motion.p>
              <motion.div className="cta" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8, delay: 0.7, ease }}>
                <span className="button soon"><i className="pulse" />{t.soon}</span>
                <a className="button ghost" href={REPO}><GitHubMark /> {t.code}</a>
              </motion.div>
              <motion.p className="fine" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.8, delay: 0.9 }}>
                {t.fine}
              </motion.p>
            </div>
            <motion.div className="hero-phones" initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 1.1, delay: 0.35, ease }}>
              <div className="sun" aria-hidden />
              <Phone shot="painting" alt="" className="behind" />
              <Phone shot="near-miss" alt={t.heroAlt} className="front" />
            </motion.div>
          </div>
        </section>

        <div className="marquee" aria-hidden>
          <div className="marquee-track">
            {[...t.marquee, ...t.marquee].map((item, index) => (
              <span key={index}>{item}<i>✦</i></span>
            ))}
          </div>
        </div>

        <Statement key={lang} text={t.statement} />

        <section className="container demo">
          <Rise className="section-head">
            <p className="label">{t.moment.label}</p>
            <h2 className="display">{t.moment.title}</h2>
            <p className="lede">{t.moment.lede}</p>
          </Rise>
          <Rise delay={0.1}><WalkScene /></Rise>
        </section>

        <section className="container" id="how">
          <Rise className="section-head">
            <p className="label">{t.how.label}</p>
            <h2 className="display">{t.how.title}</h2>
          </Rise>
          <div className="steps-grid">
            {t.steps.map((step, index) => (
              <Rise key={shots[index]} delay={index * 0.08} className="step">
                <div className="step-shot"><Phone shot={shots[index]} alt={step.alt} /></div>
                <p className="mono">0{index + 1}</p>
                <h3>{step.title}</h3>
                <p>{step.text}</p>
              </Rise>
            ))}
          </div>
        </section>

        <section className="container privacy" id="privacy">
          <Rise className="section-head">
            <p className="label">{t.privacy.label}</p>
            <h2 className="display">{t.privacy.title}</h2>
            <p className="lede">{t.privacy.lede}</p>
          </Rise>
          <Rise delay={0.1}>
            <dl className="facts">
              {t.privacy.facts.map(([term, detail]) => (
                <div key={term}>
                  <dt className="mono">{term}</dt>
                  <dd>{detail}</dd>
                </div>
              ))}
            </dl>
            <p className="more"><a href={`${base}privacidad/`}>{t.privacy.more}</a></p>
          </Rise>
        </section>

        <section className="container numbers">
          {t.numbers.map(([value, caption], index) => (
            <Rise key={value} delay={index * 0.06} className="number">
              <p className="display">{value}</p>
              <p>{caption}</p>
            </Rise>
          ))}
        </section>

        <section className="closing">
          <TrailsCanvas tone="orange" />
          <Rise className="container closing-inner">
            <img src={asset('icon.png')} alt="" width="88" height="88" className="closing-icon" />
            <h2 className="display" lang="en">Did you two<br /><em>almost</em> meet?</h2>
            <div className="cta">
              <span className="button soon"><i className="pulse" />{t.soon}</span>
              <a className="button ghost" href={REPO}><GitHubMark /> {t.code}</a>
            </div>
          </Rise>
        </section>
      </main>

      <footer className="footer container">
        <p>© {year} Near Miss · {t.footer.license}</p>
        <nav aria-label={t.footer.links}>
          <a href={`${base}privacidad/`}>{t.footer.privacy}</a>
          <a href={ISSUES}>{t.footer.support}</a>
          <a href={REPO}>GitHub</a>
        </nav>
      </footer>
    </>
  )
}
