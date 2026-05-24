# authctl operator reference

## Request path

```text
authctl → https://auth.anmho.com/internal/*
        → Cloudflare Access (service token headers)
        → auth-api internal routes (oauth clients, resource servers)
```

`--local` skips Access and uses `http://localhost:8787/internal`.

## Credential sources

1. Flags: `--base-url`, `--access-client-id`, `--access-client-secret`
2. Environment variables
3. Vault read of `prod/apps/auth/authctl/cloudflare-access` (when `vault` works and `AUTHCTL_DISABLE_VAULT` is unset)
4. Default base URL only: `https://auth.anmho.com/internal`

Manual export:

```bash
export VAULT_ADDR="${VAULT_ADDR:-https://vault.anmho.com}"
export AUTH_INTERNAL_BASE_URL="$(vault kv get -mount=secret -field=AUTH_INTERNAL_BASE_URL prod/apps/auth/authctl/cloudflare-access)"
export CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_ID="$(vault kv get -mount=secret -field=CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_ID prod/apps/auth/authctl/cloudflare-access)"
export CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_SECRET="$(vault kv get -mount=secret -field=CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_SECRET prod/apps/auth/authctl/cloudflare-access)"
```

## `vault-env` (`~/.zshrc`)

Home-shell helper for operator work (Terraform, providers, **and authctl prod**). Not part of the auth repo; lives in dotfiles.

### `vault-env`

```bash
vault-env
```

**Phase 1 — GCP Secret Manager** (project `anmho-infra-prod`, parallel):

| Output env | GCP secret |
|------------|------------|
| `VAULT_TOKEN` | `vault-init-material` (`.root_token`) |
| `TF_VAR_vault_role_id` | `atlantis-vault-role-id` |
| `TF_VAR_vault_secret_id` | `atlantis-vault-secret-id` |

**Phase 2 — Vault KV** (uses `VAULT_TOKEN`, parallel):

| Output env | Vault path / field |
|------------|-------------------|
| `AUTH_INTERNAL_BASE_URL` | `prod/apps/auth/authctl/cloudflare-access` |
| `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_ID` | same |
| `CLOUDFLARE_ACCESS_SERVICE_TOKEN_CLIENT_SECRET` | same |
| `CLOUDFLARE_API_TOKEN` | `prod/providers/cloudflare` → `api_token` |
| `HCLOUD_TOKEN`, `NEON_API_KEY`, `RESEND_API_KEY`, `STRIPE_API_KEY`, `VERCEL_TOKEN`, `UPSTASH_*` | respective `prod/providers/*` |

Also sets `TF_VAR_vault_addr` from `VAULT_ADDR` (`https://vault.anmho.com`) and `TF_VAR_cloudflare_api_token`.

### `vault-env-persist`

Called at end of `vault-env`. Rewrites the managed section in `~/.config/secrets/env.zsh`:

```text
# BEGIN vault-env managed secrets
export VAR=...
# END vault-env managed secrets
```

Directory `~/.config/secrets` should be mode `700`; file mode `600`.

### Startup

`~/.zshrc` sources `~/.config/secrets/env.zsh` on every new shell if present. That can load `VAULT_TOKEN` and provider tokens without re-running `vault-env`, but **stale** if secrets rotated—re-run `vault-env` after rotation.

### vs authctl built-in Vault read

| Mechanism | When |
|-----------|------|
| `vault-env` | Full operator env (Terraform + all providers + authctl Access vars) in interactive shell |
| authctl `readVaultField()` | Per-invocation read of authctl Access path only; needs `vault` on PATH + valid token |
| One-shot aliases | e.g. `neon-api-key`, `vault-root-token` — print one value, no export |

For prod `authctl`, any of: exported vars from `vault-env`, persisted `env.zsh`, or authctl’s own Vault lookup.

### Prerequisites

- `gcloud` authenticated for `anmho-infra-prod`
- `vault`, `jq` on PATH
- Network to `vault.anmho.com`

## Error: missing credentials

```text
Cloudflare Access service-token credentials are missing. Run `authctl doctor --json`
```

**Fix:** `vault login` or `vault-env`, then `authctl doctor --json`, or use `--local`.

## Error: 401 Forbidden (JSON with ray_id, aud)

Request reached Cloudflare Access but the **service token was rejected** (wrong, revoked, or not bound to the auth Access app).

**Not** the same as missing credentials (authctl would fail before fetch).

**Fix:**

1. Compare Vault values to Cloudflare Zero Trust service token (Terraform source of truth).
2. Re-run `vault-env` after rotation.
3. `authctl doctor --json` — `has_access_client_id` and `has_access_client_secret` should be true.
4. Rotate via Terraform + update Vault if needed.

## Resource servers vs OAuth clients

- **Resource servers** — API/resource inventory; clients must target an active server for their stage.
- **OAuth clients** — Better Auth `oauth_client` rows; create/rotate/revoke via authctl.

```bash
authctl resource-servers upsert --resource-server billing \
  --scope invoices:read --stage prod --json
authctl clients create --client-app agent --client-identity server \
  --resource-server billing --scope invoices:read --stage prod --yes --json
```

Create returns a `vault_command` to store `client_secret` under `prod/apps/<app>/<identity>/oauth-clients/<resource-server>`.

## auth-api routes (mental model)

| Surface | Path | Auth |
|---------|------|------|
| OAuth / Better Auth | `/api/auth/*` | Protocol + app secrets |
| authctl API | `/internal/*` | Cloudflare Access service token |

Do not call `/internal/*` from browsers or unauthenticated clients.
