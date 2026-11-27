import { useEffect, useRef } from 'react'

const TONES = {
  light: { a: '255, 90, 31', b: '28, 21, 16', dots: 'rgba(28, 21, 16, 0.1)', ring: '255, 90, 31', glow: 0.35 },
  orange: { a: '255, 255, 255', b: '58, 20, 4', dots: 'rgba(255, 255, 255, 0.22)', ring: '255, 255, 255', glow: 0.5 },
}
const CYCLE = 9000

type Point = [number, number]
type Curve = [Point, Point, Point, Point]

function at(curve: Curve, t: number): Point {
  const r = 1 - t
  const a = r * r * r
  const b = 3 * r * r * t
  const c = 3 * r * t * t
  const d = t * t * t
  return [
    a * curve[0][0] + b * curve[1][0] + c * curve[2][0] + d * curve[3][0],
    a * curve[0][1] + b * curve[1][1] + c * curve[2][1] + d * curve[3][1],
  ]
}

/** Two trails cross a city and pass a few steps from each other. */
export function TrailsCanvas({ tone = 'light' }: { tone?: keyof typeof TONES }) {
  const ref = useRef<HTMLCanvasElement | null>(null)

  useEffect(() => {
    const canvas = ref.current
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return
    const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    const colors = TONES[tone]
    let frame = 0
    let width = 0
    let height = 0

    const resize = () => {
      const ratio = Math.min(window.devicePixelRatio || 1, 2)
      width = canvas.clientWidth
      height = canvas.clientHeight
      canvas.width = Math.round(width * ratio)
      canvas.height = Math.round(height * ratio)
      ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
    }

    const trail = (curves: Curve[], progress: number, rgb: string, fade: number) => {
      if (progress <= 0) return
      const steps = 120
      const limit = Math.floor(progress * steps)
      ctx.beginPath()
      let head: Point = curves[0][0]
      for (let i = 0; i <= limit; i++) {
        const t = (i / steps) * curves.length
        const index = Math.min(curves.length - 1, Math.floor(t))
        head = at(curves[index], t - index)
        if (i === 0) ctx.moveTo(head[0], head[1])
        else ctx.lineTo(head[0], head[1])
      }
      ctx.lineCap = 'round'
      ctx.lineJoin = 'round'
      ctx.shadowColor = `rgba(${rgb}, ${colors.glow * fade})`
      ctx.shadowBlur = 18
      ctx.strokeStyle = `rgba(${rgb}, ${fade})`
      ctx.lineWidth = 3
      ctx.stroke()
      ctx.shadowBlur = 0
      ctx.fillStyle = `rgba(${rgb}, ${0.18 * fade})`
      ctx.beginPath()
      ctx.arc(head[0], head[1], 13, 0, Math.PI * 2)
      ctx.fill()
      ctx.fillStyle = `rgba(${rgb}, ${fade})`
      ctx.beginPath()
      ctx.arc(head[0], head[1], 6, 0, Math.PI * 2)
      ctx.fill()
    }

    const draw = (now: number) => {
      const t = still ? 0.72 : (now % CYCLE) / CYCLE
      const w = width
      const h = height
      ctx.clearRect(0, 0, w, h)

      // Street corners, like a city seen from far above.
      ctx.fillStyle = colors.dots
      for (let x = 15; x < w; x += 30) {
        for (let y = 15; y < h; y += 30) ctx.fillRect(x - 1, y - 1, 2, 2)
      }

      const cx = w * 0.5
      const coral: Curve[] = [
        [[-0.06 * w, 0.92 * h], [0.18 * w, 1.05 * h], [0.3 * w, 0.58 * h], [cx, 0.58 * h]],
        [[cx, 0.58 * h], [0.72 * w, 0.58 * h], [0.84 * w, 0.8 * h], [1.06 * w, 1.0 * h]],
      ]
      const teal: Curve[] = [
        [[1.06 * w, 0.12 * h], [0.82 * w, 0.06 * h], [0.7 * w, 0.46 * h], [cx, 0.46 * h]],
        [[cx, 0.46 * h], [0.3 * w, 0.46 * h], [0.16 * w, 0.2 * h], [-0.06 * w, 0.3 * h]],
      ]

      const eased = Math.min(1, t / 0.6)
      const drawn = eased * eased * (3 - 2 * eased)
      const fade = t > 0.9 ? Math.max(0, 1 - (t - 0.9) / 0.1) : 1
      trail(coral, drawn, colors.a, fade)
      trail(teal, drawn, colors.b, fade)

      // The near miss: rings where the two pass each other.
      const passed = (t - 0.33) / 0.5
      if (passed > 0 && passed < 1) {
        for (const offset of [0, 0.35]) {
          const ring = passed - offset
          if (ring <= 0 || ring >= 0.65) continue
          const life = ring / 0.65
          ctx.strokeStyle = `rgba(${colors.ring}, ${0.6 * (1 - life) * fade})`
          ctx.lineWidth = 1.5
          ctx.beginPath()
          ctx.arc(cx, 0.52 * h, 10 + 60 * life, 0, Math.PI * 2)
          ctx.stroke()
        }
      }
      if (!still) frame = requestAnimationFrame(draw)
    }

    resize()
    const observer = new ResizeObserver(() => {
      resize()
      if (still) draw(0)
    })
    observer.observe(canvas)
    frame = requestAnimationFrame(draw)
    return () => {
      cancelAnimationFrame(frame)
      observer.disconnect()
    }
  }, [tone])

  return <canvas ref={ref} className="trails" aria-hidden />
}
