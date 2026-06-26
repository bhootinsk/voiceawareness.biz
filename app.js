require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const path = require('path');
const express = require('express');
const session = require('express-session');

const publicRoutes = require('./routes/public');
const adminRoutes = require('./routes/admin');
const content = require('./lib/content');
const { getAdminAuthStatus } = require('./lib/auth-config');

const app = express();
const PORT = process.env.PORT || 3000;
const isProduction = process.env.NODE_ENV === 'production';

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

if (isProduction) {
  app.set('trust proxy', true);
  // Plesk Apache terminates TLS and proxies to Node over HTTP. express-session only
  // sends the session cookie when req.secure is true (needs X-Forwarded-Proto).
  app.use((req, _res, next) => {
    if (!req.get('x-forwarded-proto')) {
      req.headers['x-forwarded-proto'] = 'https';
    }
    next();
  });
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
      secure: isProduction ? 'auto' : false,
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
  const admin = getAdminAuthStatus();
  res.json({
    ok: true,
    site: content.getSite().domain,
    pages: content.listPages().map((p) => p.slug),
    nodeEnv: process.env.NODE_ENV || 'development',
    adminAuthSource: admin.source,
    adminUsername: admin.username,
    adminEnvLoaded: admin.envFileReadable,
    writable: content.writableStatus(),
    cmsPaths: content.contentPaths(),
    processUid: typeof process.getuid === 'function' ? process.getuid() : null,
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

// Plesk runs Node via Phusion Passenger (use Restart App / tmp/restart.txt).
// Local dev and manual `node app.js` still bind to PORT.
if (typeof PhusionPassenger !== 'undefined') {
  app.listen('passenger');
} else if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`voiceawareness.biz running on http://localhost:${PORT}`);
  });
}

module.exports = app;
