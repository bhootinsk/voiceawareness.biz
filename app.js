require('dotenv').config();

const path = require('path');
const express = require('express');
const session = require('express-session');

const publicRoutes = require('./routes/public');
const adminRoutes = require('./routes/admin');
const content = require('./lib/content');

const app = express();
const PORT = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

if (isProduction) {
  app.set('trust proxy', 1);
}

app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(
  session({
    name: 'vab.sid',
    secret: process.env.SESSION_SECRET || 'voiceawareness-biz-dev-secret',
    resave: false,
    saveUninitialized: false,
    proxy: isProduction,
    cookie: {
      secure: isProduction,
      httpOnly: true,
      sameSite: 'lax',
      maxAge: 24 * 60 * 60 * 1000,
      path: '/',
    },
  })
);

app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use((req, res, next) => {
  res.locals.currentPath = req.path;
  res.locals.site = content.getSite();
  next();
});

app.get('/deploy-check', (_req, res) => {
  res.json({
    ok: true,
    site: content.getSite().domain,
    pages: content.listPages().map((p) => p.slug),
    nodeEnv: process.env.NODE_ENV || 'development',
  });
});

app.use('/', publicRoutes);
app.use('/admin', adminRoutes);

app.use((req, res) => {
  res.status(404).render('404', { title: 'Page Not Found' });
});

app.use((err, req, res, _next) => {
  console.error(err);
  res.status(500).render('error', {
    title: 'Something went wrong',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Please try again later.',
  });
});

app.listen(PORT, () => {
  console.log(`voiceawareness.biz running on http://localhost:${PORT}`);
});
