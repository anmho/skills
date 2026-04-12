# anmho/skills

Install the BlueBubbles skill:

```bash
npx skills add anmho/skills --skill bluebubbles-cli -y
```

Repository contents:

- `skills/bluebubbles-cli/SKILL.md`
- `docs/` Mintlify docs site

## Mint docs

The API reference is unified with the SDK OpenAPI source:

- `https://raw.githubusercontent.com/Jish2/bluebubbles-sdk/main/openapi.yaml`

Run locally:

```bash
npm install
npm run docs:sync-openapi
npm run docs:dev
```
