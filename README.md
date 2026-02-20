# TicketBook

A peer-to-peer ticket marketplace where **clients** post ticket booking requests and **buyers** (discount card holders) fulfill them — with an escrow wallet, OCR ticket verification, dispute resolution, and real-time notifications.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [API Reference](#api-reference)
- [Business Logic & Formulas](#business-logic--formulas)
- [Project Structure](#project-structure)
- [Data Models](#data-models)

---

## Overview

| Role | Description |
|------|-------------|
| **Client** | Needs a ticket. Posts a request specifying event, date, platform, and card required. Starts with **1000 wallet points** (₹1 = 1 point). |
| **Buyer** | Owns discount cards. Browses requests or posts offers. Books the ticket using their card at a discounted rate and earns the margin. |

The app handles the full lifecycle: request → accept → book → verify (OCR) → escrow release → review.

---

## Tech Stack

### Backend

| Technology | Version | Purpose |
|-----------|---------|---------|
| Node.js + Express | ^4.18.2 | HTTP server, REST API, middleware |
| MongoDB + Mongoose | ^8.0.3 | Database, ORM, schema validation |
| MongoDB Atlas | — | Cloud-hosted database |
| bcryptjs | ^2.4.3 | Password hashing (salt rounds = 10) |
| jsonwebtoken | ^9.0.2 | JWT authentication (7-day tokens) |
| express-validator | ^7.0.1 | Request body validation |
| multer | ^1.4.5-lts.1 | Multipart file upload handling |
| Cloudinary | ^1.41.3 | Cloud image storage |
| multer-storage-cloudinary | ^4.0.0 | Multer adapter for Cloudinary |
| Tesseract.js | ^7.0.0 | OCR — text extraction from ticket screenshots |
| sharp | ^0.34.5 | Image preprocessing pipeline before OCR |
| uuid | ^9.0.1 | Unique ID generation |
| dotenv | ^16.3.1 | Environment variable management |
| cors | ^2.8.5 | Cross-origin request support |
| nodemon | ^3.0.2 | Dev auto-restart |

### Frontend

| Technology | Version | Purpose |
|-----------|---------|---------|
| Flutter | SDK ≥3.4.3 | Cross-platform mobile UI (Android/iOS) |
| Dart | — | Language |
| provider | ^6.1.1 | State management |
| http | ^1.1.0 | REST API calls |
| shared_preferences | ^2.2.2 | Local token/session persistence |
| image_picker | ^1.0.7 | Pick ticket screenshots from gallery/camera |
| intl | ^0.18.1 | Date & number formatting |
| url_launcher | ^6.2.5 | Phone dialer & external links |
| flutter_svg | ^2.0.9 | SVG asset rendering |
| cupertino_icons | ^1.0.6 | iOS-style icon set |

---

## Architecture

```
Flutter App (Android / iOS)
        │
        │  HTTP REST (Bearer JWT)
        ▼
  Express.js API  (Node.js)
        │
   ┌────┴────────────────────────┐
   │                             │
MongoDB Atlas              Cloudinary CDN
(data store)          (ticket screenshots)
        │
   ┌────┴─────────────────┐
   │                      │
Tesseract.js OCR       Timer Service
(ticket verification)  (in-memory Map +
                        DB restore on restart)
```

---

## Getting Started

### Prerequisites

- Node.js 18+
- Flutter SDK 3.4.3+
- MongoDB Atlas account (or local MongoDB)
- Cloudinary account

### Backend Setup

```bash
# 1. Navigate to backend
cd backend

# 2. Install dependencies
npm install

# 3. Create .env file
cp .env.example .env
# Fill in values (see Environment Variables section)

# 4. Start development server
npm run dev

# 5. Start production server
npm start
```

Server runs on `http://localhost:3000` by default.

### Frontend Setup

```bash
# 1. Navigate to Flutter project
cd frontend/project

# 2. Install dependencies
flutter pub get

# 3. Run on connected device / emulator
flutter run
```

---

## Environment Variables

Create `backend/.env` with the following:

```env
# Server
PORT=3000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb+srv://<user>:<password>@cluster0.mongodb.net/?appName=Cluster0

# JWT
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d

# Timer (milliseconds) — default 5 minutes
BOOKING_TIMER_DURATION=300000

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

---

## API Reference

Base URL: `http://localhost:3000/api`

All protected routes require: `Authorization: Bearer <token>`

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/auth/register` | ❌ | Register (role: `client` or `buyer`) |
| POST | `/auth/login` | ❌ | Login, returns JWT token |
| GET | `/auth/profile` | ✅ | Get current user profile |
| PUT | `/auth/profile` | ✅ | Update profile |
| PUT | `/auth/change-password` | ✅ | Change password |

### Requests

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/requests` | ✅ Client | Create a ticket request |
| GET | `/requests/pending` | ✅ Buyer | Browse open requests |
| GET | `/requests/my-requests` | ✅ Client | Client's own requests |
| GET | `/requests/my-bookings` | ✅ Buyer | Buyer's accepted bookings |
| GET | `/requests/stats` | ✅ | Request statistics |
| GET | `/requests/:id` | ✅ | Get single request |
| POST | `/requests/:id/accept` | ✅ Buyer | Accept a request (starts 5-min timer) |
| POST | `/requests/:id/complete` | ✅ Buyer | Upload ticket screenshot (triggers OCR) |
| POST | `/requests/:id/cancel` | ✅ Client | Cancel a pending request |

### Offers

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/offers` | ✅ Buyer | Post a new offer |
| GET | `/offers` | ✅ | Browse active offers |
| GET | `/offers/my-offers` | ✅ Buyer | Buyer's own offers |
| GET | `/offers/:id` | ✅ | Get single offer |
| POST | `/offers/:id/accept` | ✅ Client | Accept an offer |
| PUT | `/offers/:id` | ✅ Buyer | Update offer |
| DELETE | `/offers/:id` | ✅ Buyer | Delete offer |

### Escrow / Dispute

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/escrow/:id/confirm` | ✅ Client | Confirm ticket → release payment to buyer |
| POST | `/escrow/:id/dispute` | ✅ Client | Raise a dispute |
| POST | `/escrow/:id/dispute/reject` | ✅ Buyer | Reject dispute (release payment anyway) |
| POST | `/escrow/:id/dispute/accept` | ✅ Buyer | Accept dispute (full refund to client) |

### Wallet

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/wallet/balance` | ✅ | Get balance + frozen amount |
| GET | `/wallet/transactions` | ✅ | Paginated transaction history |
| GET | `/wallet/earnings` | ✅ Buyer | Earnings summary |
| GET | `/wallet/savings` | ✅ Client | Savings summary |
| POST | `/wallet/add-points` | ✅ | Add points (testing only) |

### Notifications

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/notifications` | ✅ | Get all notifications |
| PUT | `/notifications/:id/read` | ✅ | Mark one as read |
| PUT | `/notifications/read-all` | ✅ | Mark all as read |
| DELETE | `/notifications/:id` | ✅ | Delete one |
| DELETE | `/notifications` | ✅ | Delete all |

### Chat

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/chat/unread-count` | ✅ | Get unread message count |
| GET | `/chat/:requestId` | ✅ | Get messages for a request |
| POST | `/chat/:requestId` | ✅ | Send a message |

### Reviews

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/reviews` | ✅ Client | Submit review after completed deal |
| GET | `/reviews/my-reviews` | ✅ | Reviews written by me |
| GET | `/reviews/user/:userId` | ✅ | Reviews received by a user |

### Users

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/users/:id` | ✅ | Get public user profile |
| GET | `/users` | ✅ | List/search users |

---

## Business Logic & Formulas

### 1. Wallet Points

- 1 point = ₹1
- **Client** starts with **1000 points** on registration
- **Buyer** starts with **0 points** on registration
- `availableBalance = balance - frozenAmount`

---

### 2. Profit Distribution (on deal completion)

Given:
- `originalPrice` — what the client pays (points frozen in escrow)
- `discountedPrice` — what the buyer actually spent using their card
- Default split: **80% to buyer, 20% app commission**

```
buyerPayment   = round(originalPrice × 80 / 100)
clientRefund   = round(originalPrice × 20 / 100)
buyerProfit    = buyerPayment − discountedPrice
appProfit      = originalPrice − buyerPayment
```

**Example** — originalPrice = ₹1000, buyer books ticket for ₹700:

| Party | Amount | Explanation |
|-------|--------|-------------|
| Client pays | ₹1000 | Frozen initially |
| Buyer receives | ₹800 | 80% of original |
| Client gets back | ₹200 | 20% savings refund |
| Buyer's profit | ₹100 | 800 − 700 |
| App commission | ₹200 | 1000 − 800 |

---

### 3. Escrow Flow

```
Client posts request
  └─▶ originalPrice FROZEN (balance unchanged, frozenAmount += originalPrice)

Buyer accepts
  └─▶ 5-minute countdown timer starts
  └─▶ Request status: pending → accepted

Buyer uploads ticket screenshot
  └─▶ Image preprocessed (sharp) → OCR (Tesseract.js)
  └─▶ Booking ID extracted → duplicate check
  └─▶ Amount verified against request
  └─▶ escrow.status = 'held'

Client confirms ticket ──▶ escrow.status = 'released'
  └─▶ completePayment() runs profit distribution
  └─▶ Request status → completed

Client raises dispute
  └─▶ escrow.status = 'disputed'
  └─▶ Buyer: accept refund (client gets back 100%) OR reject (payment releases to buyer)

Timer expires (no screenshot uploaded)
  └─▶ Request status → timeout
  └─▶ Full originalPrice refunded to client
  └─▶ Buyer earns nothing
```

---

### 4. Booking Timer

- Duration: **5 minutes** (configurable via `BOOKING_TIMER_DURATION` in ms)
- Stored in Node.js in-memory `Map<requestId, { timeoutId, expiresAt }>`
- **Server restart recovery**: on startup, queries MongoDB for all requests where `status = 'accepted'` AND `timerExpiresAt > now`, restores each timer with the exact remaining milliseconds
- If `timerExpiresAt` is already past on restart, timeout is handled immediately

---

### 5. OCR Ticket Verification Pipeline

```
Upload (JPEG/PNG/WebP, max 5MB)
  └─▶ Cloudinary (permanent storage, max 1200×1200, quality: auto)
  └─▶ Local copy → sharp preprocessing:
        • Resize to 1500px width
        • Greyscale
        • Normalize contrast
        • Sharpen edges
  └─▶ Tesseract.js OCR (eng language model)
  └─▶ Amount extraction (4-step waterfall):
        1. Find line with "Total Amount" → extract ₹ value from same line
        2. Regex split pattern (whitespace between label and value)
        3. Standard total amount regex
        4. Fallback: all rupee patterns → return maximum found
  └─▶ Booking ID extracted → sparse unique index prevents duplicates
  └─▶ Platform detected (BookMyShow, Paytm, Zomato, Swiggy, MakeMyTrip, Ticketmaster)
```

---

### 6. Rating System

After every review is saved, a Mongoose `post('save')` hook recalculates the reviewee's rating via aggregation:

```
avgRating = average of all ratings for that user
rating    = round(avgRating × 10) / 10   ← rounded to 1 decimal place
```

Duplicate reviews for the same request are blocked by a compound unique index on `{ requestId, reviewerId }`.

---

### 7. Authentication Flow

```
Register → bcrypt.hash(password, saltRounds=10) → save user
         → create wallet (client: 1000pts, buyer: 0pts)
         → jwt.sign({ userId }, JWT_SECRET, { expiresIn: '7d' })

Login    → User.findOne({ email }).select('+password')
         → bcrypt.compare(input, hash)
         → jwt.sign(...)

Protected routes → extract 'Bearer <token>'
                 → jwt.verify(token, JWT_SECRET)
                 → attach req.user, req.userId
```

Password field has `select: false` — never returned in queries by default.

---

### 8. Transaction Types

| Type | Direction | Triggered When |
|------|-----------|----------------|
| `freeze` | Client | Buyer accepts request |
| `unfreeze` | Client | Request cancelled/timed out |
| `refund` | Client | Full refund on timeout |
| `client_refund` | Client | 20% savings on deal completion |
| `debit` | Client | Net payment after deal (80% of original) |
| `buyer_earning` | Buyer | 80% of original price on deal completion |
| `app_profit` | Tracked | Commission record (no wallet entry) |
| `credit` | Any | Manual points addition |

---

## Project Structure

```
freelance/
├── README.md
├── backend/
│   ├── package.json
│   ├── eng.traineddata          # Tesseract English language model
│   ├── uploads/
│   │   └── screenshots/         # Temporary local uploads before OCR
│   └── src/
│       ├── server.js            # Entry point, DB connect, route mount
│       ├── config/
│       │   └── cloudinary.js    # Cloudinary + multer config
│       ├── controllers/
│       │   ├── auth.controller.js
│       │   ├── chat.controller.js
│       │   ├── escrow.controller.js
│       │   ├── notification.controller.js
│       │   ├── offer.controller.js
│       │   ├── request.controller.js
│       │   ├── review.controller.js
│       │   ├── user.controller.js
│       │   └── wallet.controller.js
│       ├── middleware/
│       │   ├── auth.middleware.js    # JWT verification
│       │   ├── upload.middleware.js  # Multer / Cloudinary
│       │   └── validate.middleware.js
│       ├── models/
│       │   ├── User.js
│       │   ├── Wallet.js
│       │   ├── Transaction.js
│       │   ├── Request.js
│       │   ├── Offer.js
│       │   ├── Review.js
│       │   ├── Message.js
│       │   └── Notification.js
│       ├── routes/
│       │   ├── auth.routes.js
│       │   ├── chat.routes.js
│       │   ├── escrow.routes.js
│       │   ├── notification.routes.js
│       │   ├── offer.routes.js
│       │   ├── request.routes.js
│       │   ├── review.routes.js
│       │   ├── user.routes.js
│       │   └── wallet.routes.js
│       └── services/
│           ├── wallet.service.js           # Payment & profit logic
│           ├── timer.service.js            # Booking countdown timers
│           ├── ticketVerification.service.js  # OCR pipeline
│           └── notification.service.js
└── frontend/
    └── project/                 # Flutter app
        ├── pubspec.yaml
        ├── lib/
        │   ├── main.dart
        │   ├── core/            # Theme, constants, utilities
        │   ├── models/          # Dart data models
        │   ├── providers/       # Provider state management
        │   ├── screens/         # UI screens
        │   └── services/        # API service layer
        └── assets/
            └── images/          # Category images (movies, sports, etc.)
```

---

## Data Models

| Model | Key Fields |
|-------|-----------|
| `User` | name, email, password (hashed), role (client/buyer), rating, totalRatings, successfulDeals, cardsOwned |
| `Wallet` | userId, balance, frozenAmount, totalEarnings, totalProfit, totalSavings, totalRefunds |
| `Transaction` | walletId, userId, type, amount, description, requestId, balanceAfter |
| `Request` | clientId, buyerId, eventName, category, platform, cardName, originalPrice, discountedPrice, buyerPayment, clientRefund, buyerProfit, appProfit, status, escrow, dispute, timerStartedAt, timerExpiresAt, screenshotUrl, bookingId |
| `Offer` | buyerId, eventName, category, platform, cardName, offerAmount, discountPercent, discountedPrice, status, rejectedByClients |
| `Review` | requestId, reviewerId, revieweeId, rating (1–5), comment |
| `Message` | requestId, senderId, content, isRead |
| `Notification` | userId, type, title, message, isRead, data |
