# Deploying voiceawareness.biz on Plesk (Node.js)

This guide assumes you **remove the old WordPress subscription** for `voiceawareness.biz` and create a **fresh domain with Node.js enabled**.

---

## Phase 1 — Remove WordPress domain (Plesk)

1. Log in to **Plesk**.
2. Go to **Websites & Domains**.
3. Select **voiceawareness.biz**.
4. Click **Remove Website** (or **Delete Domain**).
   - If prompted, choose to remove web content and databases unless you need a backup.
5. Confirm deletion.

**Optional backup before delete**

- Export WordPress files via **Files** → download `httpdocs`.
- Export the WordPress database via **Databases** → **Export Dump**.

---

## Phase 2 — Add blank domain with Node.js

1. **Websites & Domains** → **Add Domain**.
2. Domain name: `voiceawareness.biz`
3. Choose your hosting subscription / IP.
4. After the domain is created, open **voiceawareness.biz** → **Node.js**.
5. Click **Enable Node.js**.
6. Set:
   | Setting | Value |
   |---------|--------|
   | **Node.js version** | 18.x or 20.x (LTS) |
   | **Document root** | `httpdocs` |
   | **Application mode** | `production` |
   | **Application root** | Domain root, e.g. `/var/www/vhosts/voiceawareness.biz` |
   | **Application startup file** | `app.js` |
   | **Custom environment variables** | see below |

7. Do **not** install WordPress. Leave the site as an empty Node.js app shell.

---

## Phase 3 — DNS (if not already set)

| Host | Type | Value |
|------|------|--------|
| `@` | A | Your server IP |
| `www` | CNAME or A | `@` or same IP |

Wait for DNS to propagate before issuing SSL.

---

## Phase 4 — Deploy code from GitHub

### Option A — Git in Plesk (recommended)

1. **Websites & Domains** → **voiceawareness.biz** → **Git**.
2. **Add Repository**:
   - URL: `https://github.com/bhootinsk/voiceawareness.biz.git`
   - Branch: `main`
   - Deployment path: domain root (same as application root)
3. Deploy / pull the repository.
4. Open **SSH Terminal** (or SSH from your PC):

```bash
cd /var/www/vhosts/voiceawareness.biz
npm install --production
cp .env.example .env
nano .env
```

### Option B — Clone via SSH

```bash
cd /var/www/vhosts
# if domain folder exists but is empty:
cd voiceawareness.biz
git clone https://github.com/bhootinsk/voiceawareness.biz.git .
npm install --production
cp .env.example .env
nano .env
```

---

## Phase 5 — Environment variables

Edit `.env` on the server (or set the same keys in **Node.js → Custom environment variables** in Plesk):

```env
NODE_ENV=production
PORT=3000
SESSION_SECRET=use-a-long-random-string-here
ADMIN_USERNAME=your-admin-user
ADMIN_PASSWORD=your-strong-password
```

**Important:** Change the default admin password before going live.

If Plesk assigns a different port automatically, use that port in `.env` and in `httpdocs/.htaccess` (see Phase 7).

---

## Phase 6 — File permissions

```bash
cd /var/www/vhosts/voiceawareness.biz
chown -R <plesk-subscription-user>:psacln .
chmod 755 app.js
chmod -R 775 uploads content data
```

Replace `<plesk-subscription-user>` with the system user shown in Plesk for this subscription (often the domain name).

Writable folders (admin uploads + CMS edits):

- `uploads/`
- `content/`
- `data/`

---

## Phase 7 — Document root & proxy

Plesk should use **httpdocs** as the public web root. This repo includes `httpdocs/.htaccess` to proxy requests to Node.

1. **Hosting Settings** → confirm **Document root** = `httpdocs`
2. Ensure **Apache proxy modules** are enabled (Plesk usually handles this when Node.js is enabled).
3. If your Node app runs on a port other than `3000`, edit `httpdocs/.htaccess`:

```apache
RewriteRule ^(.*)$ http://127.0.0.1:YOUR_PORT/$1 [P,L]
```

The port is shown in **Node.js** settings after you click **Restart App**.

---

## Phase 8 — SSL certificate

1. **Websites & Domains** → **voiceawareness.biz** → **SSL/TLS Certificates**
2. Install **Let's Encrypt** for:
   - `voiceawareness.biz`
   - `www.voiceawareness.biz`
3. Enable **Redirect from HTTP to HTTPS**.

---

## Phase 9 — Start & verify

1. In Plesk **Node.js**, click **NPM install** (if offered), then **Restart App**.
2. Visit:
   - `https://www.voiceawareness.biz/` — home page
   - `https://www.voiceawareness.biz/deploy-check` — JSON health check
   - `https://www.voiceawareness.biz/admin` — CMS login

Expected `/deploy-check` response:

```json
{
  "ok": true,
  "site": "voiceawareness.biz",
  "pages": ["approach", "stress-management", "..."]
}
```

---

## Phase 10 — Post-launch checklist

- [ ] Log in to `/admin` and confirm you can edit home content
- [ ] Upload a test image in **Media**
- [ ] Submit the contact form and confirm redirect to `/thank-you`
- [ ] Confirm Jane App / calendar links work
- [ ] Remove any leftover WordPress DNS or old `.biz` redirects if they exist elsewhere

---

## Updating the site later

```bash
cd /var/www/vhosts/voiceawareness.biz
git pull origin main
npm install --production
```

Then **Restart App** in Plesk Node.js (or use Plesk Git auto-deploy if configured).

---

## Troubleshooting

| Symptom | Likely fix |
|---------|------------|
| 502 Bad Gateway | Node app not running — check Plesk Node.js logs, verify `app.js` path |
| Static files 404 | Confirm `public/` exists at application root; restart Node |
| Admin login fails | Check `ADMIN_USERNAME` / `ADMIN_PASSWORD` in `.env` and restart app |
| CMS save fails | Fix permissions on `content/`, `data/`, `uploads/` (`775`) |
| Wrong port | Match `.env` `PORT`, Plesk Node.js port, and `httpdocs/.htaccess` |
| Session lost on login | Ensure `NODE_ENV=production`, SSL enabled, and `trust proxy` is active (already set in `app.js`) |

---

## Admin access

- **URL:** `https://www.voiceawareness.biz/admin`
- **Credentials:** values from `.env` on the server

Keep credentials out of Git. Never commit `.env`.
