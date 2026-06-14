const fs = require('fs');
const path = require('path');
const { marked } = require('marked');

const ROOT = path.join(__dirname, '..');
const CONTENT = path.join(ROOT, 'content');
const DATA = path.join(ROOT, 'data');

marked.setOptions({ gfm: true, breaks: true });

function readJson(filePath, fallback = null) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return fallback;
  }
}

function writeJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
}

function enrichContent(item) {
  if (!item) return null;
  const html = item.bodyFormat === 'html' ? item.body || '' : marked.parse(item.body || '');
  return { ...item, html };
}

function getSite() {
  return readJson(path.join(DATA, 'site.json'), {});
}

function saveSite(site) {
  writeJson(path.join(DATA, 'site.json'), site);
}

function listPages() {
  const dir = path.join(CONTENT, 'pages');
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith('.json'))
    .map((f) => enrichContent(readJson(path.join(dir, f))))
    .filter(Boolean)
    .sort((a, b) => (a.navOrder || 99) - (b.navOrder || 99));
}

function getPage(slug) {
  const page = readJson(path.join(CONTENT, 'pages', `${slug}.json`));
  return page ? enrichContent(page) : null;
}

function savePage(page) {
  page.updatedAt = new Date().toISOString();
  if (!page.createdAt) page.createdAt = page.updatedAt;
  writeJson(path.join(CONTENT, 'pages', `${page.slug}.json`), page);
  return enrichContent(page);
}

function getHome() {
  return readJson(path.join(CONTENT, 'home.json'), {});
}

function saveHome(home) {
  home.updatedAt = new Date().toISOString();
  writeJson(path.join(CONTENT, 'home.json'), home);
  return home;
}

function listMedia() {
  const uploads = path.join(ROOT, 'uploads');
  if (!fs.existsSync(uploads)) return [];
  return fs
    .readdirSync(uploads)
    .filter((f) => f !== '.gitkeep')
    .map((filename) => ({
      filename,
      url: `/uploads/${filename}`,
      size: fs.statSync(path.join(uploads, filename)).size,
      mtime: fs.statSync(path.join(uploads, filename)).mtime,
    }))
    .sort((a, b) => b.mtime - a.mtime);
}

function dashboardStats() {
  return {
    pages: listPages().length,
    media: listMedia().length,
  };
}

module.exports = {
  getSite,
  saveSite,
  listPages,
  getPage,
  savePage,
  getHome,
  saveHome,
  listMedia,
  dashboardStats,
};
