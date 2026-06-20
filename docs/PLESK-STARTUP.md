# Plesk Node.js startup & Restart App (voiceawareness.biz)

Plesk manages Node.js with **Phusion Passenger**. Use **Enable Node.js** and **Restart App** in the panel — not `nohup node app.js`.

`app.js` is written for Passenger (`app.listen('passenger')`) and still works locally with `npm start`.

---

## One-time setup in Plesk

### 1. Stop the manual Node process (SSH as root)

```bash
pkill -f "node app.js" 2>/dev/null; ss -tlnp | grep 3000 || echo "port 3000 free"
```

### 2. Node.js settings

**Websites & Domains** → **voiceawareness.biz** → **Node.js**

| Setting | Value |
|---------|--------|
| **Node.js version** | 24.x (match `/opt/plesk/node/24`) |
| **Application mode** | `production` |
| **Application root** | `httpdocs` |
| **Document root** | `httpdocs` |
| **Application startup file** | `app.js` |

### 3. Environment variables

Click **Custom environment variables** → **specify** and add (same values as `httpdocs/.env`):

| Name | Example |
|------|---------|
| `NODE_ENV` | `production` |
| `SESSION_SECRET` | long random string |
| `ADMIN_USERNAME` | your admin user |
| `ADMIN_PASSWORD` | your strong password |

Do not commit `.env` to Git.

### 4. Install dependencies

- Click **NPM Install** in the Node.js screen, **or** if that fails (known on some servers):

```bash
cd /var/www/vhosts/voiceawareness.biz/httpdocs; export PATH=/opt/plesk/node/24/bin:$PATH; npm install --production
```

### 5. Enable the app

Click **Enable Node.js**, then **Restart App**.

Check **Application URL** in the panel or visit:

- https://www.voiceawareness.biz/deploy-check

### 6. Apache proxy (important)

If you previously added **Additional Apache directives** with `ProxyPass` to port `3000`, **remove them** when using Plesk Node.js / Passenger. Passenger serves the app itself; keeping both can cause conflicts.

Leave `httpdocs/.htaccess` as comments-only (no `ProxyPass` there).

Reload Apache if you change directives:

```bash
plesk sbin httpdmng --reconfigure-domain voiceawareness.biz
```

### 7. SSH shell (for Git deploy actions)

**Websites & Domains** → **voiceawareness.biz** → **Web Hosting Access** → **Access to the server over SSH** → `/bin/bash` (for subscription user `voiceawarenessbiz`).

---

## After code updates

### Option A — Plesk Restart App (panel)

1. Deploy new files (Git or rsync).
2. SSH: `npm install --production` in `httpdocs` if `package.json` changed.
3. **Node.js** → **Restart App**.

### Option B — `tmp/restart.txt` (SSH or Git deploy hook)

Passenger watches this file; updating it restarts the app:

```bash
cd /var/www/vhosts/voiceawareness.biz/httpdocs; export PATH=/opt/plesk/node/24/bin:$PATH; npm install --production; mkdir -p tmp; touch tmp/restart.txt
```

### Option C — Full deploy one-liner (rsync from GitHub)

```bash
cd /var/www/vhosts/voiceawareness.biz; cp httpdocs/.env /root/vab.env.bak 2>/dev/null; rm -rf /tmp/vab-update; git clone https://github.com/bhootinsk/voiceawareness.biz.git /tmp/vab-update; rsync -av /tmp/vab-update/ httpdocs/ --exclude .env --exclude node_modules --exclude uploads --exclude .git; cp /root/vab.env.bak httpdocs/.env 2>/dev/null; cd httpdocs; export PATH=/opt/plesk/node/24/bin:$PATH; npm install --production; mkdir -p tmp; touch tmp/restart.txt; sleep 3; curl -sk https://www.voiceawareness.biz/deploy-check; echo ""
```

If Passenger is active, use `curl` to the **public URL** (not `127.0.0.1:3000`).

---

## Plesk Git auto-deploy (optional)

**Websites & Domains** → **Git** → add `https://github.com/bhootinsk/voiceawareness.biz.git` (branch `main`).

Enable **Additional deployment actions**:

```bash
(PATH=/opt/plesk/node/24/bin:$PATH; cd $HOME/httpdocs && npm install --production &> npm-install.log) && mkdir -p tmp && touch tmp/restart.txt
```

Adjust path if Git deploys to domain root instead of `httpdocs`.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| 503 after Enable Node.js | Ensure `app.js` does not only use `app.listen(3000)` without Passenger support; deploy latest `app.js` and Restart App |
| Site works on 3000 but not HTTPS | Stop `nohup node`; enable Plesk Node.js; remove Apache `ProxyPass` to 3000 |
| Restart App does nothing | `mkdir -p httpdocs/tmp && touch httpdocs/tmp/restart.txt` |
| NPM Install button fails | Use SSH `npm install --production` as `voiceawarenessbiz` |
| Admin login fails | Set env vars in Plesk Node.js screen and Restart App |
| App stops after reboot | Confirm **Node.js** shows **Enabled**; Passenger starts with Apache — no separate `nohup` needed |

### Logs

- Plesk: **Websites & Domains** → **Logs** → Log Browser (Node.js / Passenger).
- SSH: `tail -50 /var/www/vhosts/voiceawareness.biz/httpdocs/npm-install.log` (if using Git deploy actions).

---

## Quick reference

| Task | Action |
|------|--------|
| Start / restart app | Plesk → Node.js → **Restart App** |
| Restart via SSH | `touch /var/www/vhosts/voiceawareness.biz/httpdocs/tmp/restart.txt` |
| Stop manual Node | `pkill -f "node app.js"` |
| Health check | https://www.voiceawareness.biz/deploy-check |
