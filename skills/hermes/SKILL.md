---
name: hermes
description: >-
  Route Hermes everyday-assistant requests that need current web information,
  cited web search, page inspection, real browser navigation, screenshots,
  forms, menu comparison, events, shopping or travel lookup, and authenticated
  web workflows. Use when a user asks to search the web, open or inspect a
  page, compare live pages, find current events, or operate a website.
---

# Hermes

Use this skill when the user needs current web information or page-level web
interaction. The goal is to use live tools instead of explaining that access is
missing.

## Activation Triggers

Load this skill when the user asks to:

- search the web, look up current info, check latest status, compare current
  options, or find events
- open a URL, inspect a page, summarize visible page content, check a screenshot,
  navigate a site, click controls, fill a form, or compare web pages
- use a browser for menus, calendars, tickets, products, travel, maps, account
  dashboards, login-backed workflows, or other web apps
- verify claims against live sources, cite current sources, or gather evidence
  from specific sites

Do not load this skill for stable general knowledge, simple writing, coding
questions whose answer is already in the repo, or calculations that do not need
current web state.

## Tool Routing

Choose the narrowest live path that matches the task.

### Search Only

Use web search when the user needs broad or current information across sources:

- news, prices, policy, releases, schedules, events, product availability, or
  recommendations that change over time
- "search the web", "latest", "current", "today", "this weekend", or similar
  freshness language
- source discovery before deciding which pages need deeper inspection

For search answers, cite sources and include enough date/source context that the
user can tell what was checked. Do not cite sources you did not inspect.

### Browser Only

Use browser access when the user gives a page, app, or website to operate:

- open this page, inspect this URL, take a screenshot, compare these pages, or
  tell me what is visible here
- click, navigate, fill non-sensitive form fields, filter, sort, submit a safe
  workflow, or verify page state
- authenticated sessions where the browser already has a session or the user
  completes login themselves

For browser work, report what was observed or changed on the page. If a site
requires login, ask the user to complete the login in the browser; do not ask
them to paste passwords, one-time codes, cookies, or session tokens into chat.

### Search Then Browser

Use search first and browser second when the task needs discovery plus detailed
page inspection:

- find events this weekend, then inspect organizer or venue pages for dates,
  prices, and availability
- compare menus or products when the user names places but does not provide
  direct URLs
- locate official pages, then open them to inspect details, forms, screenshots,
  or current page state

Prefer official or primary sources for final details. If only secondary sources
are available, label that limitation.

## Answer Discipline

- Separate live evidence from static model knowledge.
- Use concrete dates for relative time requests such as today, tomorrow, or this
  weekend.
- Summarize source agreement and conflicts instead of flattening uncertainty.
- Keep citations close to the claims they support.
- For page inspection, say what page or URL was inspected and whether the answer
  came from visible content, a form result, or a search result.
- If live tools are unavailable, say what could not be checked and answer only
  from available evidence.

## Boundaries

- Do not browse for stable facts unless the user asks for verification or live
  sources.
- Do not request, store, or expose passwords, one-time codes, cookies, bearer
  tokens, API keys, private keys, or session values.
- Do not bypass paywalls, CAPTCHAs, rate limits, access controls, robots
  protections, or site security.
- Do not perform unsafe automation such as financial transactions, purchases,
  irreversible account changes, scraping at scale, spam, credential stuffing, or
  actions that violate a site's terms.
- For sensitive account workflows, use the browser only for user-directed,
  reversible inspection or drafting. Ask for confirmation before any meaningful
  submission, and leave credential entry to the user.
