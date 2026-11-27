import { motion, useInView, useReducedMotion } from 'motion/react'
import { useEffect, useRef, useState } from 'react'
import { useLang } from './lang'

const MINE = 'M 96 498 C 150 430, 150 330, 236 300 S 310 262, 318 262'
const THEIRS = 'M 812 30 C 760 90, 770 190, 690 214 S 600 246, 590 250'
const WALK = 3.4

const copy = {
  es: {
    aria: 'Animación: dos personas caminan y se detienen a 300 metros una de la otra, en la misma calle, el mismo día.',
    you: 'Tú',
    label: '{t.label}',
    date: '{t.date}',
    same: 'el mismo día',
    note: '{t.note}',
  },
  en: {
    aria: 'Animation: two people walk and stop 300 meters from each other, on the same street, on the same day.',
    you: 'You',
    label: 'Near miss 1 of 2 · The closest',
    date: 'March 17, 2018',
    same: 'the same day',
    note: 'You and Beto, about a 4 min walk apart, without knowing it.',
  },
}

const blocks: { x: number; y: number; w: number; h: number; park?: boolean; tone: number }[] = []
for (let row = 0; row < 4; row++) {
  for (let col = 0; col < 6; col++) {
    const park = row >= 1 && row <= 2 && col >= 2 && col <= 3
    if (park) continue
    blocks.push({ x: 20 + col * 146, y: 16 + row * 126, w: 126, h: 106, tone: (row * 7 + col * 3) % 4 })
  }
}

/** The moment the app shows: two people walk their last steps and stop 300 m apart. */
export function WalkScene() {
  const ref = useRef<HTMLDivElement | null>(null)
  const inView = useInView(ref, { amount: 0.45 })
  const reduced = useReducedMotion()
  const [run, setRun] = useState(0)
  const t = copy[useLang().lang]

  useEffect(() => {
    if (!inView || reduced) return
    setRun((value) => value + 1)
    const timer = window.setInterval(() => setRun((value) => value + 1), 9000)
    return () => window.clearInterval(timer)
  }, [inView, reduced])

  const walking = !reduced && run > 0
  const after = (delay: number) => ({
    initial: walking ? { opacity: 0 } : false,
    animate: { opacity: 1 },
    transition: { duration: 0.5, delay: walking ? delay : 0 },
  })

  return (
    <div ref={ref} className="scene" role="img" aria-label={t.aria}>
      <div className="scene-pill">
        <span><i className="dot mine" />{t.you}</span>
        <span><i className="dot theirs" />Beto</span>
      </div>

      <div className="scene-tilt">
        <svg key={run} viewBox="0 0 900 524" aria-hidden>
          <defs>
            <mask id="walk-mine">
              <motion.path d={MINE} pathLength={1} stroke="#fff" strokeWidth="26" fill="none" strokeDasharray="1" initial={{ strokeDashoffset: walking ? 1 : 0 }} animate={{ strokeDashoffset: 0 }} transition={{ duration: WALK, ease: [0.3, 0.6, 0.3, 1] }} />
            </mask>
            <mask id="walk-theirs">
              <motion.path d={THEIRS} pathLength={1} stroke="#fff" strokeWidth="26" fill="none" strokeDasharray="1" initial={{ strokeDashoffset: walking ? 1 : 0 }} animate={{ strokeDashoffset: 0 }} transition={{ duration: WALK, ease: [0.3, 0.6, 0.3, 1] }} />
            </mask>
            <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
              <feGaussianBlur stdDeviation="7" />
            </filter>
          </defs>

          {blocks.map((b) => (
            <rect key={`${b.x}-${b.y}`} x={b.x} y={b.y} width={b.w} height={b.h} rx="10" className={`block tone-${b.tone}`} />
          ))}
          <rect x="312" y="142" width="272" height="232" rx="14" className="park" />
          <g className="park-paths">
            <path d="M312 258 H584 M448 142 V374 M312 142 L584 374 M584 142 L312 374" />
            <circle cx="448" cy="258" r="20" />
          </g>

          <motion.g {...after(WALK + 0.1)}>
            <ellipse cx="454" cy="256" rx="176" ry="150" className="reach" />
            <path d="M318 262 L590 250" className="gap" />
          </motion.g>

          <g mask="url(#walk-mine)">
            <path d={MINE} className="steps-glow mine" filter="url(#glow)" />
            <path d={MINE} className="steps mine" />
          </g>
          <g mask="url(#walk-theirs)">
            <path d={THEIRS} className="steps-glow theirs" filter="url(#glow)" />
            <path d={THEIRS} className="steps theirs" />
          </g>

          <motion.g className="walker mine" style={{ offsetPath: `path("${MINE}")`, offsetRotate: '0deg' }} initial={{ offsetDistance: walking ? '0%' : '100%' }} animate={{ offsetDistance: '100%' }} transition={{ duration: WALK, ease: [0.3, 0.6, 0.3, 1] }}>
            <circle r="26" className="halo" filter="url(#glow)" />
            <circle r="15" />
          </motion.g>
          <motion.g className="walker theirs" style={{ offsetPath: `path("${THEIRS}")`, offsetRotate: '0deg' }} initial={{ offsetDistance: walking ? '0%' : '100%' }} animate={{ offsetDistance: '100%' }} transition={{ duration: WALK, ease: [0.3, 0.6, 0.3, 1] }}>
            <circle r="26" className="halo" filter="url(#glow)" />
            <circle r="15" />
          </motion.g>
        </svg>
      </div>

      <motion.div key={`pill-${run}`} className="scene-distance" {...after(WALK + 0.3)}>300 m</motion.div>

      <motion.div key={`card-${run}`} className="scene-card" initial={walking ? { opacity: 0, y: 14 } : false} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: walking ? WALK + 0.5 : 0, ease: [0.23, 1, 0.32, 1] }}>
        <p className="label accent">{t.label}</p>
        <p className="scene-date">{t.date}</p>
        <p className="scene-meters">300 m <span>{t.same}</span></p>
        <p className="scene-note">{t.note}</p>
      </motion.div>
    </div>
  )
}
