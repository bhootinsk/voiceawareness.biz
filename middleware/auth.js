function requireAuth(req, res, next) {
  if (req.session && req.session.authenticated) {
    return next();
  }
  const redirect = encodeURIComponent(req.originalUrl || '/admin');
  res.redirect(`/admin/login?session=1&redirect=${redirect}`);
}

module.exports = { requireAuth };
