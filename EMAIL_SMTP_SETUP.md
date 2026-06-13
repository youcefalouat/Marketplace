# Email Verification & SMTP Configuration Guide

## Overview

The email verification system uses SMTP to send verification emails. Configuration lives in `appsettings.json` (or environment variables for secrets).

---

## Recommended: Brevo (formerly SendinBlue)

**Why Brevo?**
- Generous free plan: 300 emails/day, no credit card required
- High deliverability (proper DKIM/SPF setup out of the box)
- Simple SMTP integration — works with existing `SmtpEmailService`
- Reliable transactional email support

### Brevo Setup Steps

1. Create a free account at [brevo.com](https://www.brevo.com)
2. Go to **Settings → SMTP & API → SMTP tab**
3. Copy your SMTP credentials

### appsettings.json (Brevo)

```json
"Email": {
  "SmtpHost": "smtp-relay.brevo.com",
  "SmtpPort": 587,
  "UseSsl": true,
  "SenderEmail": "your-verified-sender@yourdomain.com",
  "SenderName": "Marketplace Controlée",
  "BaseUrl": "https://your-production-domain.com"
}
```

### Environment Variables

```bash
# Set this — never put the password in appsettings.json
SMTP_PASSWORD=your_brevo_smtp_api_key
```

> **Note**: For Brevo, the SMTP password is your **API key** (not your account password).  
> The `Username` field in `EmailSettings` is optional; if omitted, `SenderEmail` is used as the SMTP login.

---

## Gmail SMTP

Only suitable for development/testing. Gmail requires an App Password (2FA must be enabled).

```json
"Email": {
  "SmtpHost": "smtp.gmail.com",
  "SmtpPort": 587,
  "UseSsl": true,
  "SenderEmail": "your-address@gmail.com",
  "SenderName": "Marketplace Controlée",
  "BaseUrl": "https://your-domain.com"
}
```

```bash
SMTP_PASSWORD=your_gmail_app_password
```

**How to get a Gmail App Password:**
1. Enable 2-Step Verification at [myaccount.google.com](https://myaccount.google.com)
2. Go to **Security → App Passwords**
3. Generate a password for "Mail" + your device
4. Use that 16-character password as `SMTP_PASSWORD`

> **Warning**: Gmail limits outgoing emails and is unsuitable for production use.

---

## SendGrid

```json
"Email": {
  "SmtpHost": "smtp.sendgrid.net",
  "SmtpPort": 587,
  "UseSsl": true,
  "SenderEmail": "noreply@yourdomain.com",
  "SenderName": "Marketplace Controlée",
  "Username": "apikey",
  "BaseUrl": "https://your-domain.com"
}
```

```bash
SMTP_PASSWORD=SG.your_sendgrid_api_key_here
```

> **Note**: SendGrid always uses `"apikey"` as the SMTP username (literally that string).  
> Set the `Username` field in `EmailSettings` to `"apikey"`.

---

## Mailgun

```json
"Email": {
  "SmtpHost": "smtp.mailgun.org",
  "SmtpPort": 587,
  "UseSsl": true,
  "SenderEmail": "noreply@mg.yourdomain.com",
  "SenderName": "Marketplace Controlée",
  "Username": "postmaster@mg.yourdomain.com",
  "BaseUrl": "https://your-domain.com"
}
```

```bash
SMTP_PASSWORD=your_mailgun_smtp_password
```

---

## Full appsettings.json Example

```json
{
  "Email": {
    "SmtpHost": "smtp-relay.brevo.com",
    "SmtpPort": 587,
    "UseSsl": true,
    "SenderEmail": "noreply@yourdomain.com",
    "SenderName": "Marketplace Controlée",
    "BaseUrl": "https://yourdomain.com"
  }
}
```

---

## Flutter / Mobile Configuration

No additional Flutter configuration is needed for email sending — that happens on the backend.

The mobile app only:
1. Calls `POST /api/auth/resend-verification` to trigger a new email
2. Listens to the `myapp://email-verified` deep link to confirm verification

### Deep Link (Android) — already configured

`android/app/src/main/AndroidManifest.xml` contains:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="myapp"/>
</intent-filter>
```

### Deep Link (iOS) — add to Info.plist

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>myapp</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.marketplace.app</string>
  </dict>
</array>
```

---

## Rate Limiting

The `POST /api/auth/resend-verification` endpoint enforces **1 request per 60 seconds per email address**, implemented via `IMemoryCache`. No additional configuration required.

---

## Production Security Checklist

- [ ] Set `SMTP_PASSWORD` as an environment variable (never in source code)
- [ ] Use a dedicated sender domain (e.g., `noreply@yourdomain.com`) with SPF + DKIM records
- [ ] Set `Email:BaseUrl` to your actual production HTTPS URL
- [ ] Set `JwtSettings:SecretKey` to a strong random string (32+ chars)
- [ ] Enable HTTPS in production (`UseHttpsRedirection`)
- [ ] Review CORS policy — restrict `AllowAll` to specific origins in production

---

## Verification Flow

```
User registers
    │
    ▼
Backend creates user (EmailVerified=false)
    │
    ▼
Backend sends verification email (async, non-blocking)
    │
    ▼
Mobile navigates to EmailVerificationScreen
    │
    ├── User clicks link in email
    │       │
    │       ▼
    │   Backend verifies token → sets EmailVerified=true, VerifiedAt=now
    │       │
    │       ▼
    │   HTML page attempts redirect to myapp://email-verified
    │       │
    │       ▼
    │   App receives deep link → refreshes user → navigates to HomeScreen
    │
    └── User taps "Renvoyer le lien" (rate limited: 1/60s)
            │
            ▼
        POST /api/auth/resend-verification
```
