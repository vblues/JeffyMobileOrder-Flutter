# Jeffy Mobile Order - Flutter Web Application

## Project Overview

This is a Flutter web application that replaces the existing React.js mobile ordering system. The app provides a complete online ordering experience for restaurants/stores, including menu browsing, cart management, payment processing, and order tracking.

## Technology Stack

- **Framework:** Flutter Web
- **UI Library:** GetWidget (open-source UI component library)
- **State Management:** BLoC (Business Logic Component) pattern
- **Routing:** GoRouter (URL-based navigation)
- **HTTP Client:** Dio with interceptors
- **Local Storage:** localStorage (Web API)
- **Payment Gateway:** Mastercard Payment Gateway (JavaScript interop)

## Key Features

### 1. Store Locator Entry Point
- Users access the app via GUID-based URLs
- Quick Service: `/locate/{storeId}`
- Table Service: `/locate/{storeId}/{sessionId}`
- Fetches store configuration and initializes app

### 2. Authentication
- Phone number + PIN login
- Guest mode
- OTP verification for new users
- PDPA acceptance

### 3. Menu & Products
- Category-based navigation (main & sub-categories)
- Product grid with images, prices
- Search functionality
- Product details with modifiers and combos

### 4. Shopping Cart
- Add/remove items
- Quantity management
- Product customization display
- Persistent cart (localStorage)

### 5. Order Flow
- Sales type selection (dine-in, takeaway, delivery)
- Payment method selection
- Multiple payment options:
  - Credit/Debit card
  - Pay at counter
  - Loyalty programs (cashback, stored-value, prepaid)
- Staff discounts and vouchers

### 6. Payment Integration
- Mastercard Payment Gateway integration
- Redemption PIN for loyalty payments
- Payment confirmation screens

### 7. User Profile
- View/edit profile
- View loyalty balances
- Top-up credit
- Order history

### 8. Additional Features
- Terms & Conditions
- Privacy Policy
- Refund Policy
- Feedback form

## Application Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (UI Screens, Widgets, BLoC)        │
├─────────────────────────────────────┤
│         Domain Layer                │
│  (Business Logic, Use Cases)        │
├─────────────────────────────────────┤
│         Data Layer                  │
│  (Repositories, API, Storage)       │
└─────────────────────────────────────┘
```

### Feature-Based Structure

Each feature is self-contained:
- **UI Layer:** Screens and widgets
- **BLoC Layer:** State management
- **Data Layer:** Models and repositories

### Core Services

- **API Client:** Handles all HTTP requests with MD5 signing
- **Web Storage:** Manages localStorage operations
- **Router:** URL-based navigation with deep linking
- **Dependency Injection:** GetIt for service location

## Responsive Design

The app is designed to work across all screen sizes:

- **Mobile:** < 600px (primary target)
- **Tablet:** 600px - 1024px
- **Desktop:** > 1024px

GetWidget components are configured to adapt to different screen sizes.

## Entry Point Flow

### Quick Service Flow
```
User accesses: /locate/{storeId}
        ↓
Extract storeId from URL
        ↓
Call locateStoreById(storeId, null)
        ↓
Store config in localStorage
        ↓
Navigate to /auth/login or /home
        ↓
User browses menu and orders
        ↓
Checkout (takeaway/delivery)
```

### Table Service Flow
```
User scans QR code: /locate/{storeId}/{sessionId}
        ↓
Extract storeId and sessionId from URL
        ↓
Call locateStoreById(storeId, sessionId)
        ↓
Store config + hasTableService flag
        ↓
Navigate to /auth/login
        ↓
Input table number
        ↓
User browses menu and orders
        ↓
Checkout (dine-in)
```

## API Integration

All APIs match the existing React.js implementation:

### Authentication APIs
- `userLogin()` - Login with phone + PIN
- `getOTP()` - Request OTP for verification
- `activateAdvocadoUser()` - Activate new user

### Store APIs
- `locateStoreById()` - Initialize store configuration
- `getMenu()` - Fetch menu categories
- `getProductByStore()` - Fetch all products
- `getProductAtt()` - Fetch product modifiers
- `getActivityComboWithPrice()` - Fetch combo pricing

### Order APIs
- `mobileOrderRequest()` - Submit order
- `paymentUpdate()` - Update payment status

### CRM APIs
- `getCustomerInfo()` - Fetch user profile
- `advocadoTopUpCredit()` - Process top-up

### Request Signing
All API requests include MD5 signature headers:
- `X-Tenant-Id`
- `X-App-Key`
- `X-Timestamp`
- `X-Signature` (MD5 hash)

## Data Persistence

### localStorage Keys
- `STORE_CREDENTIALS` - API credentials
- `STORE_INFO` - Store information
- `STORE_ID` - Current store ID
- `USER_INFO` - User profile data
- `BASKET` - Shopping cart items
- `HAS_TABLE_SERVICE` - Table service flag
- `SESSION_ID` - Table session ID

## State Management

BLoC pattern is used for predictable state management:

### Key BLoCs
- **StoreLocatorBloc** - Store initialization
- **AuthBloc** - User authentication
- **MenuBloc** - Menu and products
- **CartBloc** - Shopping cart
- **PaymentBloc** - Payment processing
- **UserBloc** - User profile

### State Flow
```
User Action (UI Event)
        ↓
BLoC receives event
        ↓
BLoC calls repository
        ↓
Repository calls API
        ↓
BLoC emits new state
        ↓
UI rebuilds with new state
```

## Payment Gateway Integration

Mastercard Payment Gateway is integrated via JavaScript interop:

```dart
// Dart code calls JavaScript
@JS('Checkout.configure')
external void configureCheckout(dynamic config);

@JS('Checkout.showPaymentPage')
external void showPaymentPage();
```

The payment gateway script is loaded in `web/index.html`.

## Deployment

### Build Command
```bash
flutter build web --release --web-renderer canvaskit
```

### Output Directory
```
build/web/
├── index.html
├── main.dart.js
├── flutter.js
├── assets/
└── ...
```

Deploy contents to web server root directory.

## Development Workflow

1. **Phase-based Development:** Implement features incrementally
2. **Test Each Phase:** Verify functionality before proceeding
3. **Hot Reload:** Fast development iteration
4. **Browser DevTools:** Debug in browser console

## Improvements Over React App

1. **Better Performance:** Compiled to JavaScript with optimizations
2. **Type Safety:** Dart's strong typing prevents runtime errors
3. **Cleaner Code:** BLoC pattern separates concerns
4. **Responsive UI:** Better component adaptation across screen sizes
5. **Single Codebase:** No separate mobile/desktop versions needed
6. **Modern Features:** PWA support, offline capabilities
7. **Better State Management:** Predictable state with BLoC
8. **GetWidget Components:** Professional, pre-built UI components

## Testing Strategy

- **Unit Tests:** Test BLoC logic and utilities
- **Widget Tests:** Test UI components
- **Integration Tests:** Test complete user flows
- **Manual Testing:** Browser testing across devices

## Browser Support

- Chrome (recommended)
- Safari
- Firefox
- Edge
- Mobile browsers (iOS Safari, Chrome Mobile)

## Next Steps

See IMPLEMENTATION_PLAN.md for detailed, phase-by-phase implementation steps.
