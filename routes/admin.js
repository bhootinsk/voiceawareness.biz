const path = require('path');
const fs = require('fs');
const express = require('express');
const multer = require('multer');

const content = require('../lib/content');
const { parseHomeLayout, mergeHomeLayout } = require('../lib/home-layout');
const { requireAuth } = require('../middleware/auth');
const { verifyAdminLogin, getAdminCredentials, trimCredential } = require('../lib/auth-config');

const router = express.Router();

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, path.join(__dirname, '..', 'uploads')),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname);
      const base = path.basename(file.originalname, ext).replace(/[^a-z0-9-_]/gi, '-');
      cb(null, `${base}-${Date.now()}${ext}`);
    },
  }),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(jpe?g|png|gif|webp|svg|pdf)$/i;
    if (allowed.test(file.originalname)) cb(null, true);
    else cb(new Error('File type not allowed'));
  },
});

function adminLocals(req) {
  return { adminUser: req.session.username };
}

function setFlash(req, message, level = 'success') {
  req.session.flash = { message, level };
}

function saveOrFlash(req, res, redirectTo, saveFn, successMessage) {
  try {
    saveFn();
    setFlash(req, successMessage);
    res.redirect(redirectTo);
  } catch (err) {
    console.error(`Admin save failed (${redirectTo}):`, err);
    const hint =
      err.code === 'EACCES'
        ? 'Server cannot write content files. SSH as root and run: bash /var/www/vhosts/voiceawareness.biz/scripts/fix-cms-permissions.sh'
        : err.message;
    setFlash(req, `Save failed: ${hint}`, 'error');
    res.redirect(redirectTo);
  }
}

router.use((req, res, next) => {
  if (req.session.flash) {
    res.locals.flash = req.session.flash;
    delete req.session.flash;
  }
  next();
});

function safeRedirect(path) {
  if (typeof path === 'string' && path.startsWith('/') && !path.startsWith('//')) {
    return path;
  }
  return '/admin';
}

router.get('/login', (req, res) => {
  if (req.session.authenticated) return res.redirect('/admin');
  res.render('admin/login', {
    title: 'Admin Login',
    redirect: safeRedirect(req.query.redirect),
    error: req.query.error,
    sessionLost: req.query.session === '1',
  });
});

router.post('/login', (req, res) => {
  const { user, pass, redirect } = req.body;
  const target = safeRedirect(redirect);

  if (verifyAdminLogin(user, pass)) {
    const creds = getAdminCredentials();
    req.session.regenerate((err) => {
      if (err) {
        console.error('Admin session regenerate failed:', err.message);
        return res.redirect(`/admin/login?error=1&redirect=${encodeURIComponent(target)}`);
      }
      req.session.authenticated = true;
      req.session.username = creds.username;
      req.session.save((saveErr) => {
        if (saveErr) {
          console.error('Admin session save failed:', saveErr.message);
          return res.redirect(`/admin/login?error=1&redirect=${encodeURIComponent(target)}`);
        }
        res.redirect(target);
      });
    });
    return;
  }
  console.warn('Admin login failed for username:', trimCredential(user) || '(empty)');
  res.redirect(`/admin/login?error=1&redirect=${encodeURIComponent(target)}`);
});

router.post('/logout', requireAuth, (req, res) => {
  req.session.destroy(() => res.redirect('/admin/login'));
});

router.get('/', requireAuth, (req, res) => {
  res.render('admin/dashboard', {
    title: 'Dashboard',
    stats: content.dashboardStats(),
    ...adminLocals(req),
  });
});

router.get('/site', requireAuth, (req, res) => {
  res.render('admin/site', { title: 'Site Settings', site: content.getSite(), ...adminLocals(req) });
});

router.post('/site', requireAuth, (req, res) => {
  const site = { ...content.getSite(), ...req.body };
  if (req.body.services) {
    try {
      site.services = JSON.parse(req.body.services);
    } catch {
      /* keep existing */
    }
  }
  saveOrFlash(req, res, '/admin/site', () => content.saveSite(site), 'Site settings saved.');
});

router.get('/home', requireAuth, (req, res) => {
  const home = content.getHome();
  res.render('admin/home-edit', {
    title: 'Edit Home Page',
    home: { ...home, layout: mergeHomeLayout(home.layout) },
    ...adminLocals(req),
  });
});

router.post('/home', requireAuth, (req, res) => {
  const home = content.getHome();
  const updated = {
    ...home,
    heroEyebrow: req.body.heroEyebrow,
    heroTitle: req.body.heroTitle,
    heroLead: req.body.heroLead,
    aboutTitle: req.body.aboutTitle,
    aboutSubtitle: req.body.aboutSubtitle,
    aboutBody: req.body.aboutBody,
    servicesTitle: req.body.servicesTitle,
    servicesIntro: req.body.servicesIntro,
    audienceTitle: req.body.audienceTitle,
    audienceIntro: req.body.audienceIntro,
    audienceItems: req.body.audienceItems
      ? req.body.audienceItems.split('\n').map((s) => s.trim()).filter(Boolean)
      : home.audienceItems,
    approachesTitle: req.body.approachesTitle,
    approachesItems: req.body.approachesItems
      ? req.body.approachesItems.split('\n').map((s) => s.trim()).filter(Boolean)
      : home.approachesItems,
    faqsTitle: req.body.faqsTitle,
    layout: parseHomeLayout(req.body, home.layout),
  };

  if (req.body.faqsJson) {
    try {
      updated.faqs = JSON.parse(req.body.faqsJson);
    } catch {
      /* keep existing */
    }
  }

  saveOrFlash(req, res, '/admin/home', () => content.saveHome(updated), 'Home page content saved.');
});

router.get('/pages', requireAuth, (req, res) => {
  res.render('admin/pages-list', {
    title: 'Pages',
    pages: content.listPages(),
    ...adminLocals(req),
  });
});

router.get('/pages/edit/:slug', requireAuth, (req, res) => {
  const page = content.getPage(req.params.slug);
  if (!page) return res.status(404).send('Not found');
  res.render('admin/page-edit', { title: 'Edit Page', page, ...adminLocals(req) });
});

router.post('/pages/save', requireAuth, (req, res) => {
  const body = req.body;
  const existing = content.getPage(body.slug);
  const page = {
    ...(existing || {}),
    title: body.title,
    slug: body.slug,
    metaDescription: body.metaDescription || body.excerpt,
    body: body.body,
    bodyFormat: body.bodyFormat || 'markdown',
    navOrder: Number(body.navOrder) || existing?.navOrder || 99,
  };
  saveOrFlash(
    req,
    res,
    `/admin/pages/edit/${page.slug}`,
    () => content.savePage(page),
    `Page "${page.title}" saved.`
  );
});

router.get('/media', requireAuth, (req, res) => {
  res.render('admin/media', {
    title: 'Media Library',
    media: content.listMedia(),
    ...adminLocals(req),
  });
});

router.post('/media/upload', requireAuth, upload.array('files', 12), (req, res) => {
  setFlash(req, `${req.files.length} file(s) uploaded.`);
  res.redirect('/admin/media');
});

router.post('/media/delete', requireAuth, (req, res) => {
  const file = path.basename(req.body.filename);
  const target = path.join(__dirname, '..', 'uploads', file);
  if (fs.existsSync(target)) fs.unlinkSync(target);
  setFlash(req, 'File deleted.');
  res.redirect('/admin/media');
});

module.exports = router;
