import { Backpack, Droplet, Flashlight, Footprints, Shirt, BookOpen, Apple } from 'lucide-react'
import { Reveal } from '@/components/reveal'

const ITEMS = [
  { icon: Backpack, label: 'Mochila' },
  { icon: Droplet, label: 'Água' },
  { icon: Flashlight, label: 'Lanterna' },
  { icon: Footprints, label: 'Calçado adequado' },
  { icon: Shirt, label: 'Casaco' },
  { icon: BookOpen, label: 'Bíblia' },
  { icon: Apple, label: 'Lanche' },
]

export function WhatToBring() {
  return (
    <section className="mx-auto max-w-5xl px-6 py-24 sm:py-32">
      <div className="mb-12 text-center">
        <p className="mb-3 text-xs font-medium uppercase tracking-[0.25em] text-primary">
          Preparação
        </p>
        <h2 className="font-display text-4xl font-semibold uppercase tracking-tight text-foreground text-balance sm:text-5xl">
          O que levar
        </h2>
      </div>

      <ul className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4">
        {ITEMS.map((item, i) => {
          const Icon = item.icon
          return (
            <Reveal key={item.label} delay={i * 60}>
              <li className="flex flex-col items-center gap-3 rounded-lg border border-border bg-card p-6 text-center transition hover:border-primary/50">
                <span className="flex h-12 w-12 items-center justify-center rounded-full bg-accent/50 text-primary-foreground">
                  <Icon className="h-5 w-5" aria-hidden />
                </span>
                <span className="text-sm font-medium text-foreground">{item.label}</span>
              </li>
            </Reveal>
          )
        })}
      </ul>
    </section>
  )
}
