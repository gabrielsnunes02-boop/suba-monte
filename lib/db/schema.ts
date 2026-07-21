import { pgTable, serial, text, timestamp } from "drizzle-orm/pg-core"

export const registrations = pgTable("registrations", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  phone: text("phone").notNull(),
  email: text("email"),
  church: text("church"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
})

export type Registration = typeof registrations.$inferSelect
