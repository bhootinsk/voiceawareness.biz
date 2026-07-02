const nodemailer = require('nodemailer');

function smtpConfigured() {
  return Boolean(process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASS);
}

function getContactTo() {
  return process.env.CONTACT_TO || process.env.SMTP_USER || 'info@voiceawareness.ca';
}

function getContactFrom() {
  return process.env.CONTACT_FROM || process.env.SMTP_USER || getContactTo();
}

function createTransporter() {
  if (!smtpConfigured()) {
    throw new Error('SMTP is not configured. Set SMTP_HOST, SMTP_USER, and SMTP_PASS in .env');
  }

  const port = Number(process.env.SMTP_PORT || 587);
  const secure = process.env.SMTP_SECURE === 'true' || port === 465;

  return nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port,
    secure,
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
    tls: process.env.SMTP_TLS_REJECT_UNAUTHORIZED === 'false' ? { rejectUnauthorized: false } : undefined,
  });
}

function buildContactText(data) {
  const lines = [
    'New contact form submission',
    '',
    `Name: ${data.firstName} ${data.lastName}`.trim(),
    `Email: ${data.email}`,
    `Phone: ${data.phone || '(not provided)'}`,
    `Located in Canada: ${data.inCanada === 'yes' ? 'Yes' : 'No'}`,
    '',
    'Message:',
    data.message,
    '',
    `Site: ${data.siteDomain || 'voiceawareness'}`,
    `Submitted: ${new Date().toISOString()}`,
  ];
  return lines.join('\n');
}

async function sendContactEmail(data) {
  const transporter = createTransporter();
  const to = getContactTo();
  const from = getContactFrom();
  const subject = `Website contact: ${data.firstName} ${data.lastName}`.trim();

  await transporter.sendMail({
    from: `"Voice Awareness Website" <${from}>`,
    to,
    replyTo: data.email,
    subject,
    text: buildContactText(data),
  });
}

module.exports = {
  smtpConfigured,
  getContactTo,
  sendContactEmail,
};
