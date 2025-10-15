# Jeffy Mobile Order - Flutter Web

A modern Flutter web application for the Jeffy mobile ordering system, replacing the legacy React.js implementation with improved performance and maintainability.

## 🚀 Project Overview

This is a Progressive Web App (PWA) built with Flutter that enables customers to browse menus, place orders, and make payments for Quick Service and Table Service at Jeffy restaurants.

**Live Demo:** [https://mobileorderuat.jeffy.sg](https://mobileorderuat.jeffy.sg)

## ✨ Features (MVP - Quick Service)

- ✅ **Store Locator** - Access via `/locate/{storeId}` URL
- ✅ **Clean URL Routing** - No hash (#) in URLs
- ✅ **Responsive Design** - Mobile-first, works on all devices
- 🔄 **Authentication** - Login, Guest mode, OTP, Registration (In Progress)
- 🔄 **Menu Browsing** - Categories, products, modifiers (In Progress)
- 🔄 **Shopping Cart** - Add/remove items, persist to localStorage (Planned)
- 🔄 **Payment Integration** - Credit card & Pay at Counter (Planned)
- 🔄 **Order Management** - Place orders, view confirmation (Planned)

### Excluded from MVP
- Loyalty/CRM features (Advocado cashback, stored value, etc.)
- Table Service (will implement after Quick Service)
- Order History (post-MVP)
- Combo Products (future enhancement)

## 🛠️ Tech Stack

- **Framework:** Flutter 3.35.3 (Web)
- **Language:** Dart 3.9.2
- **UI Library:** GetWidget 7.0.0
- **Routing:** GoRouter 14.8.1
- **State Management:** BLoC 8.1.6
- **HTTP Client:** Dio 5.9.0
- **Local Storage:** SharedPreferences 2.5.3
- **Authentication:** MD5 signature-based API signing

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point with clean URL strategy
├── app.dart                     # App root with routing configuration
├── presentation/
│   └── pages/
│       ├── home_page.dart       # Landing page
│       └── store_locator_page.dart  # Store info display
├── domain/                      # Business logic (planned)
├── data/                        # API services & models (planned)
└── core/                        # Utilities & constants (planned)
```

## 🔧 Setup & Installation

### Prerequisites
- Flutter SDK 3.35.3 or higher
- Dart SDK 3.9.2 or higher
- Git

### Installation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vblues/JeffyMobileOrder-Flutter.git
   cd JeffyMobileOrder-Flutter
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run in development mode:**
   ```bash
   flutter run -d chrome
   ```

4. **Build for production:**
   ```bash
   flutter build web --release
   ```

## 🌐 Deployment

The built files are located in `build/web/` after running the build command. Deploy these files to your web server.

**Current Deployment:** `/var/www/mobileorder.jeffy.sg/build/web/`

### Nginx Configuration
User handles nginx configuration manually. Ensure:
- Clean URLs support (no hash routing)
- All routes redirect to `index.html`
- Proper MIME types for Flutter assets

## 📋 API Integration

The app integrates with Jeffy's backend APIs using MD5 signature authentication. Key endpoints:

- `POST /api/Store/getStoreByDeviceNo` - Fetch store configuration
- `POST /api/Product/getMenu` - Get menu categories
- `POST /api/Product/getProductByStore` - Get products
- `POST /api/Product/getProductAtt` - Get modifiers
- `POST /api/Order/submitOrder` - Submit order

See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API reference.

## 🗓️ Implementation Plan

This project follows an incremental 19-phase approach:

1. ✅ **Phase 1:** Project Setup & Routing (Complete)
2. 🔄 **Phase 2:** Store Locator Implementation (Next)
3. Authentication System
4. Menu Display
5. ... (see [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md))

**Estimated Timeline:** 4-5 weeks

## 📖 Documentation

- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - High-level architecture and features
- [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) - Detailed 19-phase development plan
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Complete API reference with examples

## 🧪 Testing

Test the store locator with the sample store:
```
https://mobileorderuat.jeffy.sg/locate/81898903-e31a-442a-9207-120e4a8f2a09
```

## 🤝 Contributing

This is a private project for Jeffy's internal use. For development questions or issues, contact the development team.

## 📝 License

Proprietary - All rights reserved by Jeffy

## 🔗 Related Projects

- Legacy React App: `/var/www/orderuat.jeffy.sg`
- Original Repository: `JeffyMobileOrder` (React.js)

---

**Current Version:** 1.0.0+1
**Last Updated:** October 2025
**Status:** Phase 1 Complete - MVP in Development
