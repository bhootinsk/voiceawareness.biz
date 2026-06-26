const fs = require('fs');
const path = require('path');
const { marked } = require('marked');
const { applyBlogMeta } = require('./blog-meta');

const ROOT = path.join(__dirname, '..');
const CONTENT = process.env.CONTENT_DIR
  ? path.resolve(process.env.CONTENT_DIR)
  : path.join(ROOT, 'content');
const DATA = process.env.DATA_DIR ? path.resolve(process.env.DATA_DIR) : path.join(ROOT, 'data');

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
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
}

function isWritableDir(dir) {
  try {
    fs.accessSync(dir, fs.constants.W_OK);
    return true;
  } catch {
    return false;
  }
}

function isWritableFile(filePath) {
  try {
    if (!fs.existsSync(filePath)) {
      return isWritableDir(path.dirname(filePath));
    }
    fs.accessSync(filePath, fs.constants.W_OK);
    return true;
  } catch {
    return false;
  }
}

function writableStatus() {
  return {
    content: isWritableDir(CONTENT),
    data: isWritableDir(DATA),
    uploads: isWritableDir(path.join(ROOT, 'uploads')),
    homeJson: isWritableFile(path.join(CONTENT, 'home.json')),
  };
}

function contentPaths() {
  return { content: CONTENT, data: DATA };
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

const BLOG_POST_SLUGS = ['anxiety'];

function listBlogPosts() {
  return BLOG_POST_SLUGS.map((slug) => {
    const post = readJson(path.join(CONTENT, 'pages', `${slug}.json`));
    if (!post) return null;
    return applyBlogMeta({ ...enrichContent(post), url: `/${slug}` });
  })
    .filter(Boolean)
    .sort((a, b) => new Date(b.publishedAt || 0) - new Date(a.publishedAt || 0));
}

function getBlogPost(slug) {
  const post = getPage(slug);
  if (!post) return null;
  return applyBlogMeta(post);
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
  listBlogPosts,
  getBlogPost,
  dashboardStats,
  writableStatus,
  contentPaths,
};
