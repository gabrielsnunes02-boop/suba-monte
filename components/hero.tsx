'use client'

import { MapPin, Calendar, Clock, Users, ChevronDown } from 'lucide-react'
import { EVENT, spotsLeft, fillPercent } from '@/lib/event'

export function Hero() {
  return (
    <section className="relative flex min-h-svh flex-col items-center justify-center overflow-hidden px-6 pb-20 pt-28 text-center">
      {/* Imagem de fundo */}
      <div className="absolute inset-0 z-0">
        <img
          src="/images/hero-bg.png"
          alt="Homens subindo uma trilha na montanha ao amanhecer, com picos iluminados pelo sol nascente"
          className="h-full w-full object-cover object-center"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-background/55 via-background/35 to-background" />
        <div className="absolute inset-0 bg-background/15" />
      </div>

      {/* Logos institucionais */}
      <div className="absolute left-1/2 top-6 z-10 flex -translate-x-1/2 items-center gap-4">
        <img
          src="/images/homens-alfa.jpg"
          alt="Logo Homens Alfa"
          className="h-12 w-12 rounded-md object-cover ring-1 ring-primary/40 sm:h-14 sm:w-14"
        />
        <span className="h-8 w-px bg-border" aria-hidden />
        <img
          src="/images/igreja-viva.png"
          alt="Logo Igreja Viva em Missões"
          className="h-12 w-auto object-contain sm:h-14"
        />
      </div>

      <div className="animate-in fade-in slide-in-from-bottom-4 duration-1000 relative z-10 mx-auto flex max-w-3xl flex-col items-center">
        <span className="mb-6 inline-flex items-center rounded-full border border-primary/40 bg-primary/10 px-4 py-1.5 text-xs font-medium uppercase tracking-[0.2em] text-primary-foreground/90">
          {EVENT.ministry} &middot; {EVENT.church}
        </span>

        <h1 className="font-display text-5xl font-bold uppercase leading-[0.95] tracking-tight text-foreground text-balance sm:text-7xl md:text-8xl">
          Alfa da Montanha
        </h1>

        <p className="mt-5 max-w-xl font-display text-xl font-medium uppercase tracking-wide text-primary-foreground/90 text-balance sm:text-2xl">
          {EVENT.tagline}
        </p>

        <p className="mt-4 max-w-lg text-base leading-relaxed text-muted-foreground text-pretty sm:text-lg">
          {EVENT.movement}
        </p>

        <ul className="mt-8 flex flex-wrap items-center justify-center gap-x-6 gap-y-3 text-sm text-foreground/80">
          <li className="flex items-center gap-2">
            <MapPin className="h-4 w-4 text-primary" aria-hidden />
            {EVENT.church}
          </li>
          <li className="flex items-center gap-2">
            <Calendar className="h-4 w-4 text-primary" aria-hidden />
            {EVENT.date}
          </li>
          <li className="flex items-center gap-2">
            <Clock className="h-4 w-4 text-primary" aria-hidden />
            {EVENT.departureTime}
          </li>
          <li className="flex items-center gap-2">
            <Users className="h-4 w-4 text-primary" aria-hidden />
            Apenas {EVENT.totalSpots} homens
          </li>
        </ul>

        <a
          href="#inscricao"
          className="mt-10 inline-flex items-center justify-center rounded-md bg-primary px-8 py-4 text-base font-semibold uppercase tracking-wider text-primary-foreground shadow-lg shadow-primary/20 transition hover:brightness-110 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
        >
          Quero subir
        </a>

        {/* Barra de vagas */}
        <div className="mt-8 w-full max-w-sm">
          <div className="mb-2 flex items-center justify-between text-xs uppercase tracking-wider text-muted-foreground">
            <span>
              {EVENT.filledSpots} de {EVENT.totalSpots} vagas preenchidas
            </span>
            <span className="text-primary-foreground/90">{spotsLeft} restantes</span>
          </div>
          <div
            className="h-2 w-full overflow-hidden rounded-full bg-stone/60"
            role="progressbar"
            aria-valuenow={EVENT.filledSpots}
            aria-valuemin={0}
            aria-valuemax={EVENT.totalSpots}
            aria-label="Vagas preenchidas"
          >
            <div
              className="h-full rounded-full bg-gradient-to-r from-primary to-trail-glow"
              style={{ width: `${fillPercent}%` }}
            />
          </div>
        </div>
      </div>

      <ChevronDown
        className="absolute bottom-6 h-6 w-6 animate-bounce text-muted-foreground"
        aria-hidden
      />
    </section>
  )
}
