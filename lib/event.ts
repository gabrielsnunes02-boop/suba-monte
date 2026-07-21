export const EVENT = {
  name: 'Alfa da Montanha',
  tagline: 'Conquistando o topo, transformando homens.',
  movement: 'Um movimento de fé, superação e irmandade.',
  ministry: 'Homens Alfa',
  church: 'Igreja Viva em Missões',
  date: 'Sábado, 12 de Julho',
  departureTime: '22h',
  returnTime: '6h',
  minAge: '16 anos',
  totalSpots: 50,
  filledSpots: 37,
} as const

export const spotsLeft = EVENT.totalSpots - EVENT.filledSpots
export const fillPercent = Math.round((EVENT.filledSpots / EVENT.totalSpots) * 100)
