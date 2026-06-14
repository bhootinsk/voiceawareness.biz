const fs = require('fs');
const path = require('path');

const CREDENTIALS_FILE = path.join(__dirname, '..', 'data', 'admin.json');

const DEFAULTS = {
  username: 'admin',
  password: 'VoiceAwareness2025!',
};

function trimOrEmpty(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function getAdminCredentials() {
  const envUser = trimOrEmpty(process.env.ADMIN_USERNAME);
  const envPass = trimOrEmpty(process.env.ADMIN_PASSWORD);
  if (envUser && envPass) {
    return { username: envUser, password: envPass, source: 'env' };
  }

  try {
    const file = JSON.parse(fs.readFileSync(CREDENTIALS_FILE, 'utf8'));
    const username = trimOrEmpty(file.username);
    const password = trimOrEmpty(file.password);
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
  return trimOrEmpty(username) === expected.username && trimOrEmpty(password) === expected.password;
}

module.exports = { getAdminCredentials, verifyAdminLogin, DEFAULTS };
