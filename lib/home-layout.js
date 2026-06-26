const DEFAULT_HOME_LAYOUT = {
  heroCopyMaxWidth: 560,
  heroEyebrowFontSize: 32,
  heroTitleFontSize: 70,
  heroImageMaxWidth: 520,
  heroGap: 2.5,
  heroButtonPaddingLeft: 136,
};

function num(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function parseHomeLayout(body, existingLayout = {}) {
  const layout = { ...DEFAULT_HOME_LAYOUT, ...existingLayout };
  layout.heroCopyMaxWidth = num(body.heroCopyMaxWidth, layout.heroCopyMaxWidth);
  layout.heroEyebrowFontSize = num(body.heroEyebrowFontSize, layout.heroEyebrowFontSize);
  layout.heroTitleFontSize = num(body.heroTitleFontSize, layout.heroTitleFontSize);
  layout.heroImageMaxWidth = num(body.heroImageMaxWidth, layout.heroImageMaxWidth);
  layout.heroGap = num(body.heroGap, layout.heroGap);
  layout.heroButtonPaddingLeft = num(body.heroButtonPaddingLeft, layout.heroButtonPaddingLeft);
  return layout;
}

function mergeHomeLayout(layout) {
  return { ...DEFAULT_HOME_LAYOUT, ...(layout || {}) };
}

module.exports = {
  DEFAULT_HOME_LAYOUT,
  parseHomeLayout,
  mergeHomeLayout,
};
