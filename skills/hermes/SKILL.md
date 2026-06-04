---
name: hermes
description: >-
  Route Hermes everyday-assistant requests for live maps, local places,
  restaurants, coffee shops, hours, distance, directions, nearby comparisons,
  and menu-based local recommendations. Use when a user asks to find, compare,
  or navigate to real-world places, or asks whether a place is open now.
---

# Hermes

Use this skill for maps and local-place work. The goal is to get current,
location-aware answers without pretending static model knowledge is live data.

## Activation Triggers

Load this skill when the user asks about:

- restaurants, coffee shops, bars, stores, venues, or services near a place
- whether a place is open now or open at a requested time
- distance, travel time, directions, routes, or "within N minutes"
- comparing nearby places by menu, cuisine, price, hours, distance, or fit
- local recommendations where the location materially affects the answer

Do not force this skill for non-local food ideation, recipes, meal planning, or
general cuisine suggestions where the user is not asking about real places.

## Location Handling

Before using live place data, establish the search area.

- If the user provides a city, neighborhood, address, landmark, venue, or saved
  context that is available in the thread, use that location.
- If the user says "near me", "nearby", "here", or asks for live location
  and no location is available, ask for an area, address, or neighborhood.
- Do not infer precise location from IP, account profile, timezone, or prior
  unrelated context.
- If a broad location is enough, say what area you are using and ask only when
  the missing detail changes the result.

## Live Tool Path

Use a live-capable path for maps and place lookups.

1. Prefer a dedicated maps or local-places tool when one is available. Use it
   for place search, current hours, open-now status, distance, directions, and
   nearby ranking.
2. If there is no dedicated maps API, use browser or web search against current
   sources such as map listings, official place pages, menu pages, or reputable
   local directories.
3. For menus, prefer the restaurant's official menu. If only third-party menus
   are available, label that limitation and avoid overclaiming freshness.
4. For hours and open-now answers, include the date, local time context, and a
   short uncertainty note because holiday hours and temporary closures can
   change.
5. For travel time or "within N minutes", state the assumed mode such as
   walking, driving, or transit. If the mode is not clear and it affects the
   answer, ask a concise follow-up or give clearly labeled alternatives.

## Recommendation Shape

When comparing local places, rank the answer by the user's stated criteria
first. Useful criteria include:

- cuisine or dietary preference
- open-now status and closing time
- travel time or distance from the stated location
- menu fit, signature dishes, price, and reservation friction
- tradeoffs and one concrete pick

Keep the answer practical: a short ranked list, why each place fits, and the
next action such as checking directions, calling, or booking.

## Safety

- Do not fabricate hours, distances, addresses, ratings, or menu items.
- Do not claim a place is open unless a live source or maps/place tool supports
  it for the relevant time.
- Do not request or expose precise live location when a neighborhood or city is
  sufficient.
- For accessibility, safety, or health-sensitive routing, surface uncertainty
  and suggest confirming with the venue.
