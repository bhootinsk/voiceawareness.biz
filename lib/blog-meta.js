const BLOG_META = {
  anxiety: {
    cardImage: '/images/blog/anxiety-card.webp',
    featuredImage: '/images/blog/anxiety-featured.webp',
    excerpt:
      'It is funny how anxiety is this one word, but it has an impact to flip your world upside down when it takes over you. A personal reflection on the hamster-on-a-wheel mind and coping mechanisms.',
    publishedAt: '2024-07-20',
    author: 'Nayab Tahir',
  },
};

function applyBlogMeta(post) {
  if (!post) return null;
  const meta = BLOG_META[post.slug] || {};
  return {
    ...post,
    cardImage: post.cardImage || meta.cardImage || '',
    featuredImage: post.featuredImage || meta.featuredImage || '',
    excerpt: post.excerpt || meta.excerpt || '',
    publishedAt: post.publishedAt || meta.publishedAt || '',
    author: post.author || meta.author || '',
  };
}

module.exports = { BLOG_META, applyBlogMeta };
