# Editing voiceawareness.biz yourself

## Admin login

**URL:** https://www.voiceawareness.biz/admin

**Username and password** are set on the server in:

`/var/www/vhosts/voiceawareness.biz/httpdocs/.env`

```env
ADMIN_USERNAME=your-username
ADMIN_PASSWORD=your-strong-password
```

To view (SSH as root):

```bash
grep ADMIN /var/www/vhosts/voiceawareness.biz/httpdocs/.env
```

**Priority order** if `.env` is missing values:

1. `ADMIN_USERNAME` / `ADMIN_PASSWORD` in `.env`
2. `data/admin.json` on the server (if created)
3. Code default: `admin` / `VoiceAwareness2025!` — change this in production via `.env`

After changing `.env`, restart the app:

```bash
systemctl restart voiceawareness-biz
```

---

## What you can change in admin (no deploy)

Log in → **Edit Home Page** (or other CMS screens).

| You can edit | Where |
|--------------|--------|
| Hero eyebrow, title, intro text | Admin → Home |
| **Hero layout sliders** (text width, font sizes, image width, gap) | Admin → Home → Hero layout |
| About Nayab section | Admin → Home |
| Services intro, audience lists, FAQs | Admin → Home |
| Other pages (approach, services, blogs) | Admin → Pages |
| Phone, email, footer text, links | Admin → Site settings |
| Upload images | Admin → Media |

Changes save to `content/` on the server and appear **immediately** after save.

### Hero layout sliders

On **Edit Home Page**, use the **Hero layout (sliders)** section:

- **Text block width** — wider if eyebrow wraps (e.g. “Voice Awareness” on a second line)
- **Eyebrow / title font size**
- **Portrait image width**
- **Gap** between text and image
- **Booking button** left padding (arrow graphic spacing)

Click **Save home page**, then refresh the public site.

---

## What still needs deploy

Global CSS changes (new sections, colors site-wide, new features) still go through:

```bash
bash /var/www/vhosts/voiceawareness.biz/scripts/deploy.sh
```

Hero slider values are stored in `content/home.json` and do **not** need deploy.
