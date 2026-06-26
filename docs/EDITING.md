# Editing voiceawareness.biz yourself

## What you can change in the admin (no deploy)

Log in at **https://www.voiceawareness.biz/admin** → **Edit Home Page** (or other CMS screens).

| You can edit | Where |
|--------------|--------|
| Hero eyebrow, title, intro text | Admin → Home |
| About Nayab section | Admin → Home |
| Services intro, audience lists, FAQs | Admin → Home |
| Other pages (approach, services, blogs) | Admin → Pages |
| Phone, email, footer text, links | Admin → Site settings |
| Upload images | Admin → Media |

Changes save to `content/` and `data/` on the server and appear **immediately** after save (no `deploy.sh` needed).

**Tip:** To shorten the hero eyebrow so it fits one line, edit the **Eyebrow** field (e.g. slightly shorter wording). That is the fastest fix without code.

---

## What still needs code + deploy

Layout and styling live in **`public/css/site.css`** and templates. Examples:

- Text column width
- Image size, gaps, fonts
- Button graphics

After we change those files in the project, deploy on the server:

```bash
bash /var/www/vhosts/voiceawareness.biz/scripts/deploy.sh
```

---

## Want more self-service layout control?

Ask to add fields in admin for things like **hero text width** or **eyebrow font size** so you can tune them without editing CSS. That is a small enhancement we can add when you want it.
