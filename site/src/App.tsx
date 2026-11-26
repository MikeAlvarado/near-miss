import { motion, useReducedMotion, useScroll, useTransform, type MotionValue } from 'motion/react'
import { useRef } from 'react'
import { ISSUES, REPO, asset, base } from './site'
import { TrailsCanvas } from './TrailsCanvas'
import { WalkScene } from './WalkScene'

const ease = [0.23, 1, 0.32, 1] as const

function Reveal({ text, start = 0 }: { text: string; start?: number }) {
  const reduced = useReducedMotion()
  return (
    <span className="line">
      {text.split(' ').map((word, index) => (
        <motion.span
          key={`${word}-${index}`}
          className="word"
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

function Rise({ children, delay = 0, className }: { children: React.ReactNode; delay?: number; className?: string }) {
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
  return (
    <div className={`phone ${className}`}>
      <img src={asset(`shots/${shot}.png`)} alt={alt} loading="lazy" decoding="async" />
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

function Statement() {
  const ref = useRef<HTMLParagraphElement | null>(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start 0.85', 'end 0.45'] })
  const words = 'Quizá ya estuvieron en la misma calle, el mismo día, a unos pasos, años antes de saber que el otro existía.'.split(' ')
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

const steps = [
  {
    n: '01',
    title: 'Lee tus fotos',
    text: 'Casi toma solo la fecha y el lugar de cada foto. No abre ni copia ninguna imagen.',
    shot: 'welcome',
    alt: 'Pantalla de bienvenida de Casi con dos rastros de luz',
  },
  {
    n: '02',
    title: 'Mándense el rastro',
    text: 'Cada quien genera un archivo pequeño con lugares aproximados y días, y se lo manda al otro por AirDrop o Mensajes.',
    shot: 'painting',
    alt: 'Mapa de México con los dos rastros pintándose en orden',
  },
  {
    n: '03',
    title: 'Pinta el mapa',
    text: 'Los dos rastros se dibujan en el orden en que pasaron y la cámara baja hasta la calle donde casi se cruzan.',
    shot: 'near-miss',
    alt: 'Mapa a nivel de calle con los dos puntos a 300 metros',
  },
]

const facts: [string, string][] = [
  ['Servidor', 'Ninguno. No hay nada que hostear ni a dónde subir tus datos.'],
  ['Cuenta', 'No hay registro, correo ni contraseña.'],
  ['Qué lee', 'La fecha y la ubicación de cada foto. Nunca la imagen.'],
  ['Precisión', 'Celdas de unos 150 m y el día. Tu pareja recibe eso, no direcciones exactas.'],
  ['Mapa', 'Es el mapa de Apple: Apple ve qué zona se muestra, no tus fotos ni tus rastros.'],
  ['Código', 'Abierto, con licencia MIT. Puedes leer cada línea.'],
]

const marquee = ['a 300 m', 'el mismo día', 'sin saberlo', 'en la misma cuadra', 'a 4 min a pie', 'tres años antes', 'en el mismo concierto', 'a una calle']

export function App() {
  const year = new Date().getFullYear()
  return (
    <>
      <div className="grain" aria-hidden />
      <header className="nav">
        <a className="brand" href={base} aria-label="Casi, inicio">
          <img src={asset('icon.png')} alt="" width="30" height="30" />
          <span>Casi</span>
        </a>
        <nav aria-label="Secciones">
          <a href="#como">Cómo funciona</a>
          <a href="#privacidad">Privacidad</a>
          <a href={REPO}><GitHubMark /> GitHub</a>
        </nav>
      </header>

      <main>
        <section className="hero">
          <TrailsCanvas />
          <div className="hero-inner container">
            <div className="hero-copy">
              <motion.p className="label coral-text" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.8 }}>
                Antes de conocerse
              </motion.p>
              <h1 className="display">
                <Reveal text="¿Casi se" />
                <Reveal text="conocen?" start={2} />
              </h1>
              <motion.p className="lede" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8, delay: 0.55, ease }}>
                Tus fotos saben dónde estuviste cada día. Las de tu pareja también. Casi las compara y pinta en un mapa las veces que estuvieron a unas calles, sin saberlo.
              </motion.p>
              <motion.div className="cta" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8, delay: 0.7, ease }}>
                <span className="button soon"><i className="pulse" />Pronto en TestFlight</span>
                <a className="button ghost" href={REPO}><GitHubMark /> Ver el código</a>
              </motion.div>
              <motion.p className="fine" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.8, delay: 0.9 }}>
                Para iPhone · Gratis · Tus fotos no salen de tu teléfono
              </motion.p>
            </div>
            <motion.div className="hero-phones" initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 1.1, delay: 0.35, ease }}>
              <Phone shot="painting" alt="" className="behind" />
              <Phone shot="near-miss" alt="Casi mostrando dos personas a 300 metros en la Alameda, el mismo día" className="front" />
            </motion.div>
          </div>
        </section>

        <div className="marquee" aria-hidden>
          <div className="marquee-track">
            {[...marquee, ...marquee].map((item, index) => (
              <span key={index}>{item}<i>✦</i></span>
            ))}
          </div>
        </div>

        <Statement />

        <section className="container demo">
          <Rise className="section-head">
            <p className="label">El momento</p>
            <h2 className="display">Baja hasta la calle<br />y los ve caminar.</h2>
            <p className="lede">El mapa se pinta año por año. Al final, la cámara vuela al lugar donde casi se cruzan y cada quien camina sus últimos pasos.</p>
          </Rise>
          <Rise delay={0.1}><WalkScene /></Rise>
        </section>

        <section className="container" id="como">
          <Rise className="section-head">
            <p className="label">Cómo funciona</p>
            <h2 className="display">Tres pasos, dos teléfonos,<br />ningún servidor.</h2>
          </Rise>
          <div className="steps-grid">
            {steps.map((step, index) => (
              <Rise key={step.n} delay={index * 0.08} className="step">
                <div className="step-shot"><Phone shot={step.shot} alt={step.alt} /></div>
                <p className="mono">{step.n}</p>
                <h3>{step.title}</h3>
                <p>{step.text}</p>
              </Rise>
            ))}
          </div>
        </section>

        <section className="container privacy" id="privacidad">
          <Rise className="section-head">
            <p className="label">Privacidad</p>
            <h2 className="display">Nada sale de tu iPhone<br />si tú no lo mandas.</h2>
            <p className="lede">Lo único que viaja es el archivo que tú decides mandarle a tu pareja. Lo demás se queda en el teléfono.</p>
          </Rise>
          <Rise delay={0.1}>
            <dl className="facts">
              {facts.map(([term, detail]) => (
                <div key={term}>
                  <dt className="mono">{term}</dt>
                  <dd>{detail}</dd>
                </div>
              ))}
            </dl>
            <p className="more"><a href={`${base}privacidad/`}>Leer la política de privacidad completa →</a></p>
          </Rise>
        </section>

        <section className="container numbers">
          {[
            ['0', 'servidores'],
            ['150 m', 'tamaño de cada celda'],
            ['2', 'teléfonos, nada más'],
            ['MIT', 'código abierto'],
          ].map(([value, caption], index) => (
            <Rise key={caption} delay={index * 0.06} className="number">
              <p className="display">{value}</p>
              <p>{caption}</p>
            </Rise>
          ))}
        </section>

        <section className="closing">
          <TrailsCanvas />
          <Rise className="container closing-inner">
            <img src={asset('icon.png')} alt="" width="88" height="88" className="closing-icon" />
            <h2 className="display">¿Y ustedes?<br />¿Casi se conocen?</h2>
            <div className="cta">
              <span className="button soon"><i className="pulse" />Pronto en TestFlight</span>
              <a className="button ghost" href={REPO}><GitHubMark /> Ver el código</a>
            </div>
          </Rise>
        </section>
      </main>

      <footer className="footer container">
        <p>© {year} Casi · Licencia MIT</p>
        <nav aria-label="Enlaces">
          <a href={`${base}privacidad/`}>Privacidad</a>
          <a href={ISSUES}>Soporte</a>
          <a href={REPO}>GitHub</a>
        </nav>
      </footer>
    </>
  )
}
