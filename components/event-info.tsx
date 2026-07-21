import { MapPin, Clock, AlarmClock, Users, Cake } from 'lucide-react'
import { Reveal } from '@/components/reveal'
import { EVENT } from '@/lib/event'

const INFO = [
  { icon: MapPin, label: 'Local de saída', value: EVENT.church },
  { icon: Clock, label: 'Horário', value: EVENT.departureTime },
  { icon: AlarmClock, label: 'Retorno', value: EVENT.returnTime },
  { icon: Users, label: 'Limite', value: `${EVENT.totalSpots} homens` },
  { icon: Cake, label: 'Idade mínima', value: EVENT.minAge },
]

export function EventInfo() {
  return (
    <section className="border-t border-border bg-secondary/40 px-6 py-24 sm:py-32">
      <div className="mx-auto max-w-5xl">
        <div className="mb-12 text-center">
          <p className="mb-3 text-xs font-medium uppercase tracking-[0.25em] text-primary">
            Fique atento
          </p>
          <h2 className="font-display text-4xl font-semibold uppercase tracking-tight text-foreground text-balance sm:text-5xl">
            Informações importantes
          </h2>
        </div>

        <dl className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {INFO.map((item, i) => {
            const Icon = item.icon
            return (
              <Reveal key={item.label} delay={i * 60}>
                <div className="flex items-start gap-4 rounded-lg border border-border bg-card p-6">
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-accent/50 text-primary-foreground">
                    <Icon className="h-5 w-5" aria-hidden />
                  </span>
                  <div>
                    <dt className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
                      {item.label}
                    </dt>
                    <dd className="mt-1 text-lg font-medium text-foreground">{item.value}</dd>
                  </div>
                </div>
              </Reveal>
            )
          })}
        </dl>
      </div>
    </section>
  )
}
