'use client'

import { useState, type FormEvent } from 'react'
import { CheckCircle2 } from 'lucide-react'
import { EVENT, spotsLeft, fillPercent } from '@/lib/event'
import { Reveal } from '@/components/reveal'

export function Registration() {
  const [submitted, setSubmitted] = useState(false)

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setSubmitted(true)
    if (typeof window !== 'undefined') {
      window.scrollTo({ top: window.scrollY, behavior: 'instant' as ScrollBehavior })
    }
  }

  return (
    <section id="inscricao" className="relative overflow-hidden px-6 py-24 sm:py-32">
      {/* Imagem do topo ao fundo */}
      <div className="absolute inset-0 -z-10">
        <img
          src="/images/topo-montanha.png"
          alt="Homens reunidos em oração no topo da montanha ao amanhecer"
          className="h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-background/85" />
        <div className="absolute inset-0 bg-gradient-to-b from-background via-background/70 to-background" />
      </div>

      <div className="mx-auto max-w-2xl">
        {/* Contador grande */}
        <div className="mb-14 text-center">
          <p className="text-xs font-medium uppercase tracking-[0.25em] text-primary">
            {EVENT.totalSpots} vagas
          </p>
          <p className="mt-4 text-sm uppercase tracking-widest text-muted-foreground">Restam</p>
          <p className="font-display text-8xl font-bold leading-none text-foreground drop-shadow-lg sm:text-9xl">
            {spotsLeft}
          </p>
          <div className="mx-auto mt-6 h-2 w-full max-w-sm overflow-hidden rounded-full bg-stone/60">
            <div
              className="h-full rounded-full bg-gradient-to-r from-primary to-trail-glow"
              style={{ width: `${fillPercent}%` }}
            />
          </div>
        </div>

        {submitted ? (
          <div className="flex flex-col items-center gap-4 rounded-xl border border-primary/40 bg-card/80 p-10 text-center backdrop-blur">
            <CheckCircle2 className="h-14 w-14 text-primary" aria-hidden />
            <h3 className="font-display text-3xl font-semibold uppercase tracking-tight text-foreground">
              Vaga garantida!
            </h3>
            <p className="max-w-md leading-relaxed text-muted-foreground text-pretty">
              Recebemos sua inscrição. Em breve entraremos em contato com os próximos passos da
              jornada. Prepare o coração — o monte espera por você.
            </p>
          </div>
        ) : (
          <Reveal>
            <div className="mb-8 text-center">
              <h2 className="font-display text-4xl font-semibold uppercase tracking-tight text-foreground text-balance sm:text-5xl">
                Garantir minha vaga
              </h2>
              <p className="mt-3 leading-relaxed text-muted-foreground">
                Preencha seus dados e dê o primeiro passo da subida.
              </p>
            </div>
            <RegistrationForm onSubmit={handleSubmit} />
          </Reveal>
        )}
      </div>
    </section>
  )
}

function RegistrationForm({ onSubmit }: { onSubmit: (e: FormEvent<HTMLFormElement>) => void }) {
  return (
    <form
      onSubmit={onSubmit}
      className="space-y-5 rounded-xl border border-border bg-card/80 p-6 backdrop-blur sm:p-8"
    >
      <Field id="nome" label="Nome completo">
        <input
          id="nome"
          name="nome"
          type="text"
          required
          autoComplete="name"
          className="form-input"
          placeholder="Seu nome"
        />
      </Field>

      <div className="grid gap-5 sm:grid-cols-2">
        <Field id="telefone" label="Telefone">
          <input
            id="telefone"
            name="telefone"
            type="tel"
            required
            autoComplete="tel"
            className="form-input"
            placeholder="(00) 00000-0000"
          />
        </Field>
        <Field id="idade" label="Idade">
          <input
            id="idade"
            name="idade"
            type="number"
            min={16}
            required
            className="form-input"
            placeholder="16+"
          />
        </Field>
      </div>

      <Field id="restricao" label="Possui alguma restrição física?">
        <textarea
          id="restricao"
          name="restricao"
          rows={2}
          className="form-input resize-none"
          placeholder="Descreva se houver. Caso contrário, deixe em branco."
        />
      </Field>

      <Field id="emergencia" label="Contato de emergência">
        <input
          id="emergencia"
          name="emergencia"
          type="text"
          required
          className="form-input"
          placeholder="Nome e telefone"
        />
      </Field>

      <label className="flex items-start gap-3 text-sm leading-relaxed text-muted-foreground">
        <input
          type="checkbox"
          name="termo"
          required
          className="mt-1 h-4 w-4 shrink-0 rounded border-border bg-background accent-primary"
        />
        <span>
          Aceito o termo de responsabilidade e estou ciente das condições da caminhada noturna.
        </span>
      </label>

      <button
        type="submit"
        className="w-full rounded-md bg-primary px-8 py-4 text-base font-semibold uppercase tracking-wider text-primary-foreground shadow-lg shadow-primary/20 transition hover:brightness-110 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
      >
        Finalizar inscrição
      </button>
    </form>
  )
}

function Field({
  id,
  label,
  children,
}: {
  id: string
  label: string
  children: React.ReactNode
}) {
  return (
    <div className="space-y-2">
      <label htmlFor={id} className="block text-sm font-medium text-foreground">
        {label}
      </label>
      {children}
    </div>
  )
}
