# Deploy voiceawareness.ca (mirror of .biz)

Clone the live **voiceawareness.biz** Node.js site onto **voiceawareness.ca** on the same Plesk server. Both sites use the **same GitHub repo**; each has its own port, systemd service, and CMS copy.

| Site | Port | systemd service | Plesk path |
|------|------|-----------------|------------|
| voiceawareness.biz | 3000 | `voiceawareness-biz` | `/var/www/vhosts/voiceawareness.biz` |
| voiceawareness.ca | 3001 | `voiceawareness-ca` | `/var/www/vhosts/voiceawareness.ca` |

**Do not use Plesk Node.js** for either domain — use **systemd + Apache proxy** (same as .biz).

---

## Before you start

1. **Back up WordPress** on voiceawareness.ca if you need anything from it (Plesk backup or export).
2. **Push latest code to GitHub** from your PC (includes new clone scripts).
3. Keep **voiceawareness.biz running** — .ca clones CMS from .biz.

---

## Part 1 — Plesk: remove WordPress, add blank domain

### 1. Remove old voiceawareness.ca (WordPress)

1. **Plesk** → **Websites & Domains**
2. Select **voiceawareness.ca**
3. **Remove Website** (or remove subscription)  
   - Confirm you have backups if needed.

### 2. Add voiceawareness.ca again

1. **Add Domain** → `voiceawareness.ca`
2. **Hosting type:** Website hosting
3. **Document root:** `httpdocs` (default)
4. **PHP / WordPress:** do **not** install WordPress
5. Finish wizard — leave site empty

### 3. Disable Plesk Node.js (important)

1. **voiceawareness.ca** → **Node.js** → **Disable Node.js**

### 4. Apache proxy → port 3001

**Websites & Domains** → **voiceawareness.ca** → **Apache & nginx Settings**  
Add to **Additional Apache directives** for **both HTTP and HTTPS**:

```apache
<IfModule mod_proxy.c>
  ProxyPreserveHost On
  RequestHeader set X-Forwarded-Proto "https"
  RequestHeader set X-Forwarded-Port "443"
  ProxyPass / http://127.0.0.1:3001/
  ProxyPassReverse / http://127.0.0.1:3001/
</IfModule>
```

**Note:** .biz uses port **3000**; .ca uses **3001**.

Ensure `httpdocs/.htaccess` has **no** active `ProxyPass` lines (comments only).

### 5. SSL

**SSL/TLS Certificates** → install Let's Encrypt for `voiceawareness.ca` and `www.voiceawareness.ca`.

### 6. SSH access

**Web Hosting Access** → enable SSH for the subscription user.

---

## Part 2 — SSH: bootstrap voiceawareness.ca

SSH as **root**: `ssh root@70.35.206.242`

### 1. Confirm Plesk created the domain folder

```bash
ls -la /var/www/vhosts/voiceawareness.ca/httpdocs
stat -c '%U' /var/www/vhosts/voiceawareness.ca/httpdocs
```

Note the **subscription username**. If it differs from `voiceawarenessca`, update after bootstrap:

```bash
nano /var/www/vhosts/voiceawareness.ca/scripts/config/voiceawareness.ca.env
```

### 2. Clone repo and run bootstrap (one-time)

```bash
rm -rf /tmp/vac-setup
git clone --depth 1 https://github.com/bhootinsk/voiceawareness.biz.git /tmp/vac-setup
bash /tmp/vac-setup/scripts/bootstrap-voiceawareness-ca.sh
```

This deploys code, copies CMS from .biz, creates `.env`, installs systemd, and reconfigures Apache.

### 3. Verify

```bash
systemctl status voiceawareness-ca
curl -s http://127.0.0.1:3001/deploy-check
```

Open https://www.voiceawareness.ca/ and https://www.voiceawareness.ca/admin

### 4. Change admin password

```bash
nano /var/www/vhosts/voiceawareness.ca/httpdocs/.env
systemctl restart voiceawareness-ca
```

---

## Part 3 — Keeping both sites in sync (mirrors)

### Code + CMS (both sites)

```bash
bash /var/www/vhosts/voiceawareness.biz/scripts/deploy-all.sh
```

### CMS mirror only (.biz → .ca)

```bash
bash /var/www/vhosts/voiceawareness.ca/scripts/sync-cms-mirror.sh
```

Each domain has separate CMS under `private/cms/`. `deploy.sh` does not overwrite CMS.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| 502 / blank page | `systemctl status voiceawareness-ca` |
| Wrong port | .ca proxy = 3001, .biz = 3000 |
| Admin login loops | Add `X-Forwarded-Proto` in Apache |
| CMS save fails | `bash .../setup-cms-storage.sh voiceawareness.ca` |

```bash
journalctl -u voiceawareness-ca -n 50 --no-pager
plesk sbin httpdmng --reconfigure-domain voiceawareness.ca
```
