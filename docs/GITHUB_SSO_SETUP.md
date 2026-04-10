# GitHub SSO setup

Optional. Lets Tari community members log in with their GitHub account
instead of creating a Discourse-local password. Recommended for Tari
because most of the community is already on GitHub contributing to
tari-project repos.

## 1. Register the OAuth app on GitHub

1. Visit <https://github.com/settings/developers> → **OAuth Apps** →
   **New OAuth App**
2. Fill in:
   - **Application name:** `Tari Community Forum`
   - **Homepage URL:** `https://<FORUM_DOMAIN>`
   - **Authorization callback URL:** `https://<FORUM_DOMAIN>/auth/github/callback`
   - **Application description:** `OAuth login for the Tari community Discourse forum.`
3. Click **Register application**
4. Copy the **Client ID**
5. Click **Generate a new client secret**, copy it immediately (GitHub only
   shows it once)

## 2. Wire it into Discourse

Edit `.env` on the host and fill in:

```
GITHUB_CLIENT_ID=<from step 1>
GITHUB_CLIENT_SECRET=<from step 1>
```

Then rebuild:

```bash
cd /opt/tari-discourse
sudo ./scripts/rebuild.sh
```

The `discourse-github-oauth2` plugin is pre-installed by `deploy/app.yml` —
it just sits dormant until the credentials are set.

After the rebuild finishes:

1. Visit `https://<FORUM_DOMAIN>/admin/site_settings/category/login`
2. Confirm **github client id** and **github client secret** are populated
3. Toggle **enable github logins** on
4. (Optional) Set **github oauth2 email verified** to `true` to trust
   verified-email claims from GitHub
5. Save

## 3. Test the flow

1. Log out (or use an incognito window)
2. Click **Log In** — a "with GitHub" button should appear
3. Authorise on GitHub
4. Confirm you get redirected back to the forum logged in as a new user
5. Merge the GitHub identity into an existing account via
   `/my/preferences/account` → **Associated Accounts** if needed

## Revoking the OAuth app

If the client secret is ever compromised:

1. GitHub → Settings → Developers → OAuth Apps → **Revoke all user tokens**
2. Generate a new client secret
3. Update `.env` on the host
4. `sudo ./scripts/rebuild.sh`

Existing logged-in sessions survive the rotation because Discourse uses
server-side session tokens independent of the OAuth secret.

## Email policy interaction

GitHub SSO users get created with the verified primary email from their
GitHub account. If they set their GitHub email to private, Discourse will
fall back to the `noreply@users.noreply.github.com` address, which is
useless for notifications. Consider setting
**auth overrides email** = `false` so users can change their forum email
after sign-up.
