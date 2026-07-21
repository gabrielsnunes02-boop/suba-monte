'use client'

import { useEffect, useRef, useState } from 'react'
import { Home, Footprints, Flame, Heart, Compass, Mountain, type LucideIcon } from 'lucide-react'
import { cn } from '@/lib/utils'

type Step = {
  icon: LucideIcon
  label: string
  title: string
  description: string
}

const STEPS: Step[] = [
  {
    icon: Home,
    label: 'Check-in',
    title: 'O ponto de partida',
    description: 'Recepção na igreja, oração inicial e alinhamento da missão.',
  },
  {
    icon: Footprints,
    label: 'Partida',
    title: 'Juntos rumo ao monte',
    description: 'Seguimos juntos, em silêncio e expectativa, em direção ao monte.',
  },
  {
    icon: Flame,
    label: 'Primeira parada',
    title: 'O chamado',
    description: 'Primeira reflexão durante a subida. Deus chama, nós respondemos.',
  },
  {
    icon: Heart,
    label: 'Segunda parada',
    title: 'Renúncia',
    description: 'Momento de oração e entrega. Deixamos o peso que nos atrasa.',
  },
  {
    icon: Compass,
    label: 'Terceira parada',
    title: 'Perseverança',
    description: 'Mesmo cansados, continuamos subindo. A recompensa está no alto.',
  },
  {
    icon: Mountain,
    label: 'Topo',
    title: 'O encontro',
    description: 'A principal ministração. Adoração, oração e comunhão.',
  },
]

export function Journey() {
  const sectionRef = useRef<HTMLDivElement>(null)
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    const onScroll = () => {
      const el = sectionRef.current
      if (!el) return
      const rect = el.getBoundingClientRect()
      const vh = window.innerHeight
      // Começa a preencher quando o topo cruza 80% da tela e termina quando o fim cruza 40%
      const start = vh * 0.8
      const end = vh * 0.4
      const total = rect.height + (start - end)
      const scrolled = start - rect.top
      const p = Math.min(1, Math.max(0, scrolled / total))
      setProgress(p)
    }
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll)
    return () => {
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }, [])

  return (
    <section className="px-6 py-16 sm:py-24">
      <div className="mx-auto mb-16 max-w-2xl text-center">
        <p className="mb-3 text-xs font-medium uppercase tracking-[0.25em] text-primary">
          A jornada
        </p>
        <h2 className="font-display text-4xl font-semibold uppercase tracking-tight text-foreground text-balance sm:text-5xl">
          Cada passo é uma decisão
        </h2>
      </div>

      <div ref={sectionRef} className="relative mx-auto max-w-3xl">
        {/* Trilho de fundo */}
        <div className="absolute bottom-0 left-6 top-0 w-px bg-stone/50 md:left-1/2 md:-translate-x-1/2" />
        {/* Trilho preenchido */}
        <div
          className="absolute left-6 top-0 w-px bg-gradient-to-b from-primary to-trail-glow shadow-[0_0_12px_var(--trail-glow)] md:left-1/2 md:-translate-x-1/2"
          style={{ height: `${progress * 100}%` }}
        />

        <ol className="space-y-14 md:space-y-20">
          {STEPS.map((step, i) => (
            <JourneyStep key={step.label} step={step} index={i} />
          ))}
        </ol>
      </div>
    </section>
  )
}

function JourneyStep({ step, index }: { step: Step; index: number }) {
  const ref = useRef<HTMLLIElement>(null)
  const [active, setActive] = useState(false)
  const Icon = step.icon
  const isLeft = index % 2 === 0

  useEffect(() => {
    const el = ref.current
    if (!el) return
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setActive(true)
          observer.disconnect()
        }
      },
      { threshold: 0.6, rootMargin: '0px 0px -20% 0px' },
    )
    observer.observe(el)
    return () => observer.disconnect()
  }, [])

  return (
    <li
      ref={ref}
      className={cn(
        'relative pl-16 transition-all duration-700 ease-out md:pl-0',
        active ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8',
      )}
    >
      {/* Nó / ponto na trilha */}
      <span
        className={cn(
          'absolute left-6 top-1 z-10 flex h-12 w-12 -translate-x-1/2 items-center justify-center rounded-full border transition-all duration-500 md:left-1/2',
          active
            ? 'border-trail-glow bg-accent text-primary-foreground shadow-[0_0_20px_var(--trail-glow)]'
            : 'border-stone bg-card text-muted-foreground',
        )}
        aria-hidden
      >
        <Icon className="h-5 w-5" />
      </span>

      {/* Conteúdo */}
      <div
        className={cn(
          'md:w-[calc(50%-3rem)]',
          isLeft ? 'md:mr-auto md:pr-4 md:text-right' : 'md:ml-auto md:pl-4 md:text-left',
        )}
      >
        <p className="text-xs font-medium uppercase tracking-[0.2em] text-primary">{step.label}</p>
        <h3 className="mt-1 font-display text-2xl font-semibold uppercase tracking-tight text-foreground">
          {step.title}
        </h3>
        <p className="mt-2 leading-relaxed text-muted-foreground text-pretty">{step.description}</p>
      </div>
    </li>
  )
}
