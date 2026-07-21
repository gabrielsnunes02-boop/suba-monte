'use client'

import { useEffect, useState } from 'react'
import { spotsLeft } from '@/lib/event'
import { cn } from '@/lib/utils'

export function StickyCta() {
  const [show, setShow] = useState(false)

  useEffect(() => {
    const onScroll = () => {
      const y = window.scrollY
      const nearBottom =
        window.innerHeight + y >= document.documentElement.scrollHeight - 900
      // Aparece depois de sair do hero e some perto da seção de inscrição
      setShow(y > window.innerHeight * 0.9 && !nearBottom)
    }
    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  return (
    <div
      className={cn(
        'fixed inset-x-0 bottom-0 z-50 border-t border-border bg-background/90 px-4 py-3 backdrop-blur transition-all duration-300',
        show ? 'translate-y-0 opacity-100' : 'pointer-events-none translate-y-full opacity-0',
      )}
    >
      <div className="mx-auto flex max-w-3xl items-center justify-between gap-4">
        <p className="text-sm text-foreground">
          <span className="font-semibold text-primary">{spotsLeft} vagas</span> restantes
        </p>
        <a
          href="#inscricao"
          className="rounded-md bg-primary px-6 py-2.5 text-sm font-semibold uppercase tracking-wider text-primary-foreground transition hover:brightness-110 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
        >
          Garantir minha vaga
        </a>
      </div>
    </div>
  )
}
