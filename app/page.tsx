import { Hero } from '@/components/hero'
import { Banner } from '@/components/banner'
import { Intro } from '@/components/intro'
import { Journey } from '@/components/journey'
import { Purpose } from '@/components/purpose'
import { WhatToBring } from '@/components/what-to-bring'
import { EventInfo } from '@/components/event-info'
import { Registration } from '@/components/registration'
import { SiteFooter } from '@/components/site-footer'
import { StickyCta } from '@/components/sticky-cta'

export default function Page() {
  return (
    <main className="relative overflow-x-hidden bg-background">
      <Hero />
      <Banner />
      <Intro />
      <Journey />
      <Purpose />
      <WhatToBring />
      <EventInfo />
      <Registration />
      <SiteFooter />
      <StickyCta />
    </main>
  )
}
