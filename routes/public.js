const express = require('express');
const content = require('../lib/content');
const { mergeHomeLayout } = require('../lib/home-layout');

const router = express.Router();

const SERVICE_SLUGS = [
  'stress-management',
  'relationship-trauma',
  'emotional-stability',
  'personal-growth',
];

router.get('/', (req, res) => {
  const home = content.getHome();
  res.render('home', {
    title: 'Psychotherapy Counseling Services',
    home: { ...home, layout: mergeHomeLayout(home.layout) },
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
  const page = content.getPage('blogs');
  if (!page) return res.status(404).render('404', { title: 'Not Found' });
  res.render('page', { title: page.title, page });
});

router.get('/calendar', (req, res) => {
  const page = content.getPage('calendar');
  if (!page) return res.status(404).render('404', { title: 'Not Found' });
  res.render('page', { title: page.title, page, wide: true });
});

router.get('/thank-you', (req, res) => {
  const page = content.getPage('thank-you');
  res.render('page', {
    title: page ? page.title : 'Thank You',
    page: page || { title: 'Thank You', html: '<p>Thank you for reaching out. We will be in touch soon.</p>' },
  });
});

router.post('/contact', (req, res) => {
  // Phase 1: acknowledge submission. Email integration can be added later.
  console.log('Contact form submission:', {
    firstName: req.body.firstName,
    lastName: req.body.lastName,
    email: req.body.email,
    phone: req.body.phone,
    message: req.body.message,
    inOntario: req.body.inOntario,
  });
  res.redirect('/thank-you');
});

module.exports = router;
module.exports.SERVICE_SLUGS = SERVICE_SLUGS;
