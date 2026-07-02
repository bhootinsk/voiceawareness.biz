const express = require('express');
const content = require('../lib/content');
const { mergeHomeLayout } = require('../lib/home-layout');
const { sendContactEmail, smtpConfigured, getContactTo } = require('../lib/mail');

const router = express.Router();

const SERVICE_SLUGS = [
  'stress-management',
  'relationship-trauma',
  'emotional-stability',
  'personal-growth',
];

router.get('/', (req, res) => {
  const home = content.getHome();
  const contactError = req.session.contactError || null;
  delete req.session.contactError;
  res.render('home', {
    title: 'Psychotherapy Counseling Services',
    home: { ...home, layout: mergeHomeLayout(home.layout) },
    contactError,
  });
});

router.get('/my-approach', (req, res) => {
  const page = content.getPage('approach');
  if (!page) return res.status(404).render('404', { title: 'Not Found' });
  res.render('page', { title: page.title, page });
});

router.get('/stress-management', renderService('stress-management'));
router.get('/cope-with-relationship-trauma', renderService('relationship-trauma'));
router.get('/drive-emotional-stability', renderService('emotional-stability'));
router.get('/enhance-personal-growth', renderService('personal-growth'));

function renderService(slug) {
  return (req, res) => {
    const page = content.getPage(slug);
    if (!page) return res.status(404).render('404', { title: 'Not Found' });
    res.render('service', { title: page.title, page });
  };
}

router.get('/blogs', (req, res) => {
  res.render('blogs', { title: 'Blogs', posts: content.listBlogPosts() });
});

router.get('/anxiety', (req, res) => {
  const page = content.getBlogPost('anxiety');
  if (!page) return res.status(404).render('404', { title: 'Not Found' });
  res.render('blog', { title: page.title, page });
});

router.get('/calendar', (req, res) => {
  const page = content.getPage('calendar');
  if (!page) return res.status(404).render('404', { title: 'Not Found' });
  res.render('calendar', { title: page.title, page });
});

router.get('/thank-you', (req, res) => {
  const page = content.getPage('thank-you');
  res.render('page', {
    title: page ? page.title : 'Thank You',
    page: page || { title: 'Thank You', html: '<p>Thank you for reaching out. We will be in touch soon.</p>' },
  });
});

router.get('/privacy-policy', (req, res) => {
  const page = content.getPage('privacy-policy');
  if (!page) return res.status(404).render('404', { title: 'Not Found' });
  res.render('page', { title: page.title, page });
});

router.post('/contact', async (req, res) => {
  const site = content.getSite();
  const payload = {
    firstName: String(req.body.firstName || '').trim(),
    lastName: String(req.body.lastName || '').trim(),
    email: String(req.body.email || '').trim(),
    phone: String(req.body.phone || '').trim(),
    message: String(req.body.message || '').trim(),
    inCanada: req.body.inOntario === 'yes' ? 'yes' : 'no',
    siteDomain: site.domain || 'voiceawareness',
  };

  if (!payload.firstName || !payload.lastName || !payload.email || !payload.message) {
    req.session.contactError = 'Please fill in all required fields.';
    return res.redirect('/#bookafreeconsulation');
  }

  if (String(req.body.captcha || '').trim() !== '17') {
    req.session.contactError = 'The security check answer was incorrect. Please try again.';
    return res.redirect('/#bookafreeconsulation');
  }

  if (!smtpConfigured()) {
    console.error('Contact form: SMTP not configured in .env');
    req.session.contactError = `Messages cannot be sent yet. Please email ${site.email || getContactTo()} directly.`;
    return res.redirect('/#bookafreeconsulation');
  }

  try {
    await sendContactEmail(payload);
    console.log('Contact form email sent for:', payload.email);
    return res.redirect('/thank-you');
  } catch (err) {
    console.error('Contact form email failed:', err.message);
    req.session.contactError = `We could not send your message. Please email ${site.email || getContactTo()} or call us.`;
    return res.redirect('/#bookafreeconsulation');
  }
});

module.exports = router;
module.exports.SERVICE_SLUGS = SERVICE_SLUGS;
