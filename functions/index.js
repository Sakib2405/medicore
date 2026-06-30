const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const sgMail = require('@sendgrid/mail');
// Load local .env when running emulator / locally
require('dotenv').config();
const axios = require('axios');

admin.initializeApp();

let smtpTransporter = null;

function getTransporter() {
  if (process.env.SENDGRID_API_KEY) {
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    return {
      sendMail: async ({ to, from, subject, html }) => {
        await sgMail.send({ to, from, subject, html });
      },
    };
  }

  if (!smtpTransporter) {
    const host = process.env.SMTP_HOST;
    const port = Number(process.env.SMTP_PORT || 587);
    const secure = process.env.SMTP_SECURE === 'true';
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (host && user && pass) {
      smtpTransporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: { user, pass },
      });
    }
  }

  return smtpTransporter;
}

async function sendMail({ to, subject, html }) {
  const from = process.env.MAIL_FROM || 'Medicore <noreply@medicore.app>';
  const transporter = getTransporter();

  if (!transporter) {
    console.warn('Email not sent: mail transport is not configured.');
    return;
  }

  await transporter.sendMail({ to, from, subject, html });
}

exports.sendCustomVerificationEmail = functions.auth.user().onCreate(async (user) => {
  const displayName = user.displayName || 'User';
  const email = user.email;

  try {
    if (!email) return;

    await sendMail({
      to: email,
      subject: 'Welcome to Medicore',
      html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #0072ff;">Welcome to Medicore</h2>
        <p>Hello ${displayName},</p>
        <p>Your account has been created successfully. You can sign in to Medicore and continue using the platform.</p>
        <hr style="margin: 30px 0;">
        <p style="color: #666; font-size: 12px;">
          Best regards,<br>
          Medicore Team
        </p>
      </div>
    `,
    });
    console.log('Welcome email sent to:', email);
  } catch (error) {
    console.error('Error sending email:', error);
  }
});

exports.notifyDoctorVerificationUpdate = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};

    if ((before.role || after.role) !== 'doctor') {
      return null;
    }

    const beforeStatus = before.verificationStatus || 'pending';
    const afterStatus = after.verificationStatus || beforeStatus;

    if (beforeStatus === afterStatus) {
      return null;
    }

    const email = after.email || before.email;
    if (!email) {
      return null;
    }

    const displayName = after.name || before.name || 'Doctor';

    if (afterStatus === 'verified') {
      await sendMail({
        to: email,
        subject: 'Your Medicore doctor account is approved',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #16a34a;">Account approved</h2>
            <p>Hello ${displayName},</p>
            <p>Your doctor account has been approved by the Medicore admin team. You can now sign in and access your doctor dashboard.</p>
            <hr style="margin: 30px 0;">
            <p style="color: #666; font-size: 12px;">
              Best regards,<br>
              Medicore Team
            </p>
          </div>
        `,
      });
      console.log('Doctor approval email sent to:', email);
    } else if (afterStatus === 'rejected') {
      await sendMail({
        to: email,
        subject: 'Medicore doctor account review update',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #dc2626;">Review update</h2>
            <p>Hello ${displayName},</p>
            <p>Your doctor account application was not approved at this time. Please contact the Medicore admin team if you believe this is a mistake or need to update your details.</p>
            <hr style="margin: 30px 0;">
            <p style="color: #666; font-size: 12px;">
              Best regards,<br>
              Medicore Team
            </p>
          </div>
        `,
      });
      console.log('Doctor rejection email sent to:', email);
    }

    return null;
  });

// HTTP proxy for Gemini / Generative AI
// POST body: { input: string, model?: string, temperature?: number, maxOutputTokens?: number }
exports.geminiProxy = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') return res.status(405).send('POST only');

    const apiKey = process.env.GEMINI_API_KEY || (functions.config && functions.config().gemini && functions.config().gemini.key);
    if (!apiKey) {
      return res.status(500).json({ error: 'GEMINI API key not configured on the server.' });
    }

    const { input, model = 'gemini-1.5-flash', temperature = 0.7, maxOutputTokens = 512 } = req.body || {};
    if (!input || typeof input !== 'string') return res.status(400).json({ error: 'Missing `input` string in request body.' });

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${apiKey}`;

    const body = {
      contents: [{
        parts: [{
          text: input
        }]
      }],
      generationConfig: {
        temperature,
        maxOutputTokens,
      }
    };

    const r = await axios.post(url, body, { headers: { 'Content-Type': 'application/json' } });
    return res.status(r.status).json(r.data);
  } catch (err) {
    console.error('geminiProxy error:', err && err.toString ? err.toString() : err);
    if (err.response && err.response.data) {
      return res.status(err.response.status || 500).json(err.response.data);
    }
    return res.status(500).json({ error: err && err.message ? err.message : String(err) });
  }
});