# Stable deployment (without Plesk Node.js)

Plesk’s Node.js UI can list versions (22, 23) that don’t match binaries on disk (`/opt/plesk/node/24`, `26`). **Do not use Plesk Node.js / Restart App** for this site.

Use instead:

1. **systemd** — runs `node app.js` on port 3000, auto-restart, starts on boot  
2. **Apache proxy** — forwards HTTPS to `127.0.0.1:3000`  
3. **`scripts/deploy.sh`** — `git clone` + `rsync` + `systemctl restart`

Node binary: **`/opt/plesk/node/24/bin/node`** (v24.17.0 on this server).

---

## One-time Plesk cleanup

1. **Websites & Domains** → **voiceawareness.biz** → **Node.js** → **Disable Node.js**  
2. **Hosting Settings** → Document root = `httpdocs`  
3. **Apache & nginx Settings** → **Additional Apache directives** (HTTP **and** HTTPS):

```apache
<IfModule mod_proxy.c>
  ProxyPreserveHost On
  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Port "443"
  ProxyPass / http://127.0.0.1:3000/
  ProxyPassReverse / http://127.0.0.1:3000/
</IfModule>
```

`X-Forwarded-Proto` is required so admin login can set the session cookie over HTTPS. Without it, sign-in succeeds but the page reloads with an empty form (no error).

4. Ensure `httpdocs/.htaccess` has **no** `ProxyPass` (comments only).

5. Reload Apache:

```bash
plesk sbin httpdmng --reconfigure-domain voiceawareness.biz
```

---

## One-time server install (SSH as root)

**One command** (paste this single line only):

```bash
curl -fsSL https://raw.githubusercontent.com/bhootinsk/voiceawareness.biz/main/scripts/server-bootstrap.sh | bash
```

Before running: disable Plesk Node.js and set Apache proxy (see above).

If `curl` fails, run commands **one at a time** (press Enter after each line):

```bash
git clone https://github.com/bhootinsk/voiceawareness.biz.git /tmp/vab-setup
```

```bash
rsync -av /tmp/vab-setup/ /var/www/vhosts/voiceawareness.biz/httpdocs/ --exclude .env --exclude node_modules --exclude uploads --exclude .git
```

```bash
cp -r /tmp/vab-setup/scripts /var/www/vhosts/voiceawareness.biz/
```

```bash
bash /var/www/vhosts/voiceawareness.biz/scripts/install-systemd.sh
```

---

## Every deploy after changes

```bash
bash /var/www/vhosts/voiceawareness.biz/scripts/deploy.sh
```

**Both domains (mirror):**

```bash
bash /var/www/vhosts/voiceawareness.biz/scripts/deploy-all.sh
```

See **[DEPLOY-VOICEAWARENESS-CA.md](./DEPLOY-VOICEAWARENESS-CA.md)** for cloning .biz → .ca.

Or manually:

```bash
systemctl restart voiceawareness-biz
curl -s http://127.0.0.1:3000/deploy-check
```

---

## Useful commands

| Task | Command |
|------|---------|
| Status | `systemctl status voiceawareness-biz` |
| Logs | `journalctl -u voiceawareness-biz -f` |
| Restart | `systemctl restart voiceawareness-biz` |
| Stop manual nohup | `pkill -f "node app.js"` |

---

## `.env` on server

```env
NODE_ENV=production
PORT=3000
SESSION_SECRET=...
ADMIN_USERNAME=...
ADMIN_PASSWORD=...
```

---

## Optional: full domain reset in Plesk

Only if the domain is badly misconfigured:

1. Backup `httpdocs/.env` and `uploads/`  
2. Remove and re-add domain (or reset hosting)  
3. **Do not** enable WordPress or Plesk Node.js  
4. Clone repo into `httpdocs`, restore `.env`  
5. Run `install-systemd.sh` and set Apache proxy as above  

---

## DNS (permanent)

If `github.com` stops resolving after reboot:

```bash
printf 'nameserver 8.8.8.8\nnameserver 1.1.1.1\n' > /etc/resolv.conf
```

For a permanent fix, set DNS in **Plesk → Tools & Settings** or `/etc/systemd/resolved.conf`.
