const fs = require('fs');
const path = require('path');

const CREDENTIALS_FILE = path.join(__dirname, '..', 'data', 'admin.json');

const DEFAULTS = {
  username: 'admin',
  password: 'VoiceAwareness2025!',
};

function trimCredential(value) {
  if (typeof value !== 'string') return '';
  let v = value.trim().replace(/\r$/, '');
  if (
    (v.startsWith('"') && v.endsWith('"')) ||
    (v.startsWith("'") && v.endsWith("'"))
  ) {
    v = v.slice(1, -1);
  }
  return v;
}

function getAdminCredentials() {
  const envUser = trimCredential(process.env.ADMIN_USERNAME);
  const envPass = trimCredential(process.env.ADMIN_PASSWORD);
  if (envUser && envPass) {
    return { username: envUser, password: envPass, source: 'env' };
  }

  try {
    const file = JSON.parse(fs.readFileSync(CREDENTIALS_FILE, 'utf8'));
    const username = trimCredential(file.username);
    const password = trimCredential(file.password);
    if (username && password) {
      return { username, password, source: 'file' };
    }
  } catch {
    /* use defaults */
  }

  return { ...DEFAULTS, source: 'default' };
}

function verifyAdminLogin(username, password) {
  const expected = getAdminCredentials();
  return trimCredential(username) === expected.username && trimCredential(password) === expected.password;
}

function getAdminAuthStatus() {
  const creds = getAdminCredentials();
  return {
    source: creds.source,
    username: creds.username,
    envFileReadable: Boolean(trimCredential(process.env.ADMIN_USERNAME) && trimCredential(process.env.ADMIN_PASSWORD)),
  };
}

module.exports = { getAdminCredentials, verifyAdminLogin, getAdminAuthStatus, trimCredential, DEFAULTS };
