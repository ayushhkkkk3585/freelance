# TicketBook Backend API

REST API backend for the TicketBook Flutter mobile application.

## Tech Stack

- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MongoDB** - Database
- **JWT** - Authentication
- **Multer** - File uploads

## Getting Started

### Prerequisites

- Node.js 18+
- MongoDB (local or Atlas)

### Installation

1. Clone and navigate to backend folder:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file from example:
```bash
cp .env.example .env
```

4. Update `.env` with your configuration:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/ticketbook
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d
BOOKING_TIMER_DURATION=300000
```

5. Start the server:
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login user |
| GET | `/api/auth/profile` | Get current user profile |
| PUT | `/api/auth/profile` | Update profile |
| PUT | `/api/auth/change-password` | Change password |

### Requests
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/requests` | Create request (Client) |
| GET | `/api/requests/pending` | Get pending requests (Buyer) |
| GET | `/api/requests/my-requests` | Get my requests (Client) |
| GET | `/api/requests/my-bookings` | Get my bookings (Buyer) |
| GET | `/api/requests/stats` | Get request statistics |
| GET | `/api/requests/:id` | Get single request |
| POST | `/api/requests/:id/accept` | Accept request (Buyer) |
| POST | `/api/requests/:id/complete` | Complete with screenshot (Buyer) |
| POST | `/api/requests/:id/cancel` | Cancel request (Client) |

### Wallet
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/wallet/balance` | Get wallet balance |
| GET | `/api/wallet/transactions` | Get transaction history |
| POST | `/api/wallet/add-points` | Add points (testing) |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/notifications` | Get notifications |
| PUT | `/api/notifications/:id/read` | Mark as read |
| PUT | `/api/notifications/read-all` | Mark all as read |
| DELETE | `/api/notifications/:id` | Delete notification |
| DELETE | `/api/notifications` | Delete all |

### Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/chat/unread-count` | Get unread count |
| GET | `/api/chat/:requestId` | Get messages |
| POST | `/api/chat/:requestId` | Send message |

### Reviews
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/reviews` | Create review |
| GET | `/api/reviews/my-reviews` | Get my reviews |
| GET | `/api/reviews/user/:userId` | Get user reviews |

## Project Structure

```
backend/
├── src/
│   ├── controllers/     # Request handlers
│   ├── middleware/      # Auth, validation, upload
│   ├── models/          # Mongoose schemas
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   └── server.js        # Entry point
├── uploads/             # Uploaded files
├── .env.example         # Environment template
├── package.json
└── README.md
```

## Business Logic

### Point System
- Client starts with 1000 points
- 1 point = ₹1
- Points frozen when buyer accepts request
- Points transferred to buyer on completion
- Points refunded to client on timeout

### Booking Timer
- 5-minute timer starts when buyer accepts
- If screenshot uploaded before timeout: booking completed
- If timer expires: automatic refund to client

### User Roles
- **Client**: Creates requests, pays with points
- **Buyer**: Accepts requests, earns points
