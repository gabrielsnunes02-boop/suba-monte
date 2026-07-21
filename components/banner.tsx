import { Reveal } from '@/components/reveal'

export function Banner() {
  return (
    <section className="px-6 pb-8">
      <Reveal>
        <figure className="mx-auto max-w-5xl overflow-hidden rounded-xl border border-border shadow-2xl shadow-black/40">
          <img
            src="/images/alfa-hero.jpg"
            alt="Arte oficial do Alfa da Montanha: homens subindo a trilha liderados por um homem com a bandeira do movimento, com o slogan Conquistando o topo, transformando homens"
            className="h-auto w-full object-cover"
          />
        </figure>
      </Reveal>
    </section>
  )
}
