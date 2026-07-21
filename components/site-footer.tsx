import { EVENT } from '@/lib/event'

export function SiteFooter() {
  return (
    <footer className="border-t border-border bg-background px-6 py-16 text-center">
      <blockquote className="mx-auto max-w-xl">
        <p className="font-display text-2xl font-medium uppercase leading-snug tracking-tight text-foreground text-balance sm:text-3xl">
          &ldquo;Subamos ao monte do Senhor.&rdquo;
        </p>
        <cite className="mt-3 block text-sm not-italic text-muted-foreground">Isaías 2.3</cite>
      </blockquote>

      <div className="mt-12 flex flex-col items-center gap-6">
        <div className="flex items-center gap-5">
          <img
            src="/images/homens-alfa.jpg"
            alt="Logo Homens Alfa"
            className="h-14 w-14 rounded-md object-cover ring-1 ring-primary/30"
          />
          <span className="h-10 w-px bg-border" aria-hidden />
          <img
            src="/images/igreja-viva.png"
            alt="Logo Igreja Viva em Missões"
            className="h-14 w-auto object-contain"
          />
        </div>

        <div className="flex flex-col items-center gap-1">
          <span className="font-display text-lg font-semibold uppercase tracking-wide text-foreground">
            {EVENT.ministry}
          </span>
          <span className="text-sm text-muted-foreground">{EVENT.church}</span>
        </div>

        <p className="text-xs uppercase tracking-wider text-muted-foreground">
          {EVENT.name} &middot; {EVENT.date}
        </p>
      </div>
    </footer>
  )
}
