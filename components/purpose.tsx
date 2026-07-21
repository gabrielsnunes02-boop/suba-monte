import { Reveal } from '@/components/reveal'

export function Purpose() {
  return (
    <section className="relative overflow-hidden border-y border-border bg-secondary/40 px-6 py-24 sm:py-32">
      <div className="mx-auto max-w-3xl text-center">
        <Reveal>
          <p className="mb-3 text-xs font-medium uppercase tracking-[0.25em] text-primary">
            O propósito
          </p>
          <h2 className="font-display text-4xl font-semibold uppercase tracking-tight text-foreground text-balance sm:text-5xl">
            Por que subir um monte?
          </h2>
        </Reveal>
        <Reveal delay={120}>
          <div className="mt-8 space-y-6 text-lg leading-relaxed text-muted-foreground text-pretty">
            <p>
              Desde a Bíblia vemos homens encontrando Deus em lugares altos. Não porque Deus esteja
              mais perto das montanhas, mas porque subir exige decisão.
            </p>
            <p>
              Cada passo representa disposição para deixar o conforto e buscar a presença de Deus.
            </p>
          </div>
        </Reveal>
      </div>
    </section>
  )
}
