import { Reveal } from '@/components/reveal'

export function Intro() {
  return (
    <section className="mx-auto max-w-3xl px-6 py-24 text-center sm:py-32">
      <Reveal>
        <h2 className="font-display text-4xl font-semibold uppercase leading-tight tracking-tight text-foreground text-balance sm:text-5xl">
          Todo homem tem um topo para conquistar.
        </h2>
      </Reveal>
      <Reveal delay={120}>
        <p className="mt-6 text-lg leading-relaxed text-muted-foreground text-pretty">
          O Alfa da Montanha não é só uma trilha. É uma expedição de fé, superação e irmandade. Cada
          passo da subida é uma decisão de deixar o velho homem para trás e buscar mais de Deus, ao
          lado de irmãos que sobem com você.
        </p>
      </Reveal>
    </section>
  )
}
