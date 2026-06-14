# voiceawareness.biz

Independent Node.js site for [voiceawareness.biz](https://www.voiceawareness.biz), derived from the structure and content of voiceawareness.ca. Fully separate from the `voiceawareness.life` project.

## Stack

- **Express.js** + **EJS** templates
- Content stored in JSON (`content/`, `data/`)
- Admin CMS at `/admin` (pages, home sections, media uploads, site settings)

## Local development

```powershell
cd D:\CURSOR\voiceawareness.biz
copy .env.example .env
npm install
npm start
```

Open http://localhost:3000

**Admin:** http://localhost:3000/admin  
Default credentials (change in `.env`): `admin` / `VoiceAwareness2025!`

## Pages

| URL | Content |
|-----|---------|
| `/` | Home (hero, about, services, FAQs, contact) |
| `/my-approach` | Therapeutic approach |
| `/stress-management` | Service page |
| `/cope-with-relationship-trauma` | Service page |
| `/drive-emotional-stability` | Service page |
| `/enhance-personal-growth` | Service page |
| `/blogs` | Blog landing |
| `/calendar` | Jane App booking embed |
| `/thank-you` | Contact form confirmation |

## GitHub

Remote: https://github.com/bhootinsk/voiceawareness.biz.git

## Deployment

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for Plesk setup.

## Next steps (optional)

- Add email delivery for the contact form (nodemailer)
- Copy portrait and branding images from voiceawareness.ca into `public/images/`
- Structured blog posts with admin CRUD
