---
summary: Sales revenue has two daily-volume tiers (weekdays vs high days); normalize for calendar mix before comparing MoM revenue.
usage_mode: auto
sort_order: 0
tags:
  - finance
  - revenue
sl_refs:
  - sales
  - sales.revenue_inr
connections:
  - warehouse
---

## Revenue Calendar Normalization

### Two-tier daily revenue pattern
Revenue in the warehouse runs at two distinct daily volume levels:
- **Normal days**: standard weekday revenue
- **High days**: roughly 2× normal-day revenue

**High days are defined as:**
- Saturdays and Sundays
- An elevated month-end window (approximately the last 5–7 days of the month)

This pattern is consistent across all channels (D2C, Platform, Qcomm, Offline, International, Cafe).

### Month-over-month comparison rule
> Before concluding that a revenue change is a performance shift, normalize for **calendar mix** (number of weekends, month-end window days, and total calendar days in the period).

A month with fewer high-volume days will mechanically produce lower revenue even if revenue per day and per unit are flat. February is the most common offender due to its shorter length and fewer weekends.

**Checklist before calling an MoM change a "performance issue":**
1. Count high days (weekends + month-end window) in each period.
2. Count total calendar days in each period.
3. Compare revenue **per day** and **per day-type** — not just raw totals.
4. Check that revenue per unit and discount rates moved; if flat, the cause is calendar mix alone.

### Source
Validated via `sales` source (all channels combined), queried by day and day-type.

