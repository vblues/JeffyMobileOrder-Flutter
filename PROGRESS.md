# Mobile Order Flutter Web App - Development Progress

**Last Updated:** Build #22 (2025-10-15)
**Project:** Flutter Web Mobile Ordering Application
**Repository:** `/var/www/mobileorder.jeffy.sg`
**Production URL:** `https://mobileorderuat.jeffy.sg`

---

## 🎯 Project Overview

A Flutter web application for mobile food ordering, designed to replace/complement the existing React application at `orderuat.jeffy.sg`. The app supports QR code-based store access, menu browsing with hierarchical categories, and product selection.

---

## ✅ Completed Features

### Phase 1: Project Foundation (Builds #1-8)
- ✅ Flutter web project initialization with clean URL routing
- ✅ Material Design 3 theme with brand colors (Orange #FF9800)
- ✅ GoRouter setup for navigation
- ✅ Home page and store locator page structure
- ✅ Dependencies configured:
  - `go_router` - Routing
  - `dio` - HTTP client
  - `flutter_bloc` - State management
  - `shared_preferences` - Local storage
  - `url_strategy` - Clean URLs without #
  - `crypto` - MD5 signing

### Phase 2: Store Locator & API Integration (Builds #9-15)
- ✅ QR code entry flow: `/locate/:storeId`
- ✅ Store locator API integration with MD5 authentication
- ✅ Two-step API flow:
  1. `locateStoreById` - Get credentials
  2. `getStoreByDeviceNo` - Get store information
- ✅ BLoC pattern state management
- ✅ Local storage caching for credentials and store info
- ✅ Comprehensive error handling

### Phase 3: Menu & Product Display (Builds #16-18)
- ✅ Menu API integration (`getMenu`, `getProductByStore`)
- ✅ Menu category display with horizontal scrollable chips
- ✅ Product grid with 2-column layout
- ✅ Product cards showing:
  - Product image with loading/error states
  - Product name (2-line max with ellipsis)
  - Price with proper formatting
  - "Add" button for cart action
  - Dine-in only indicator
- ✅ Product detail page with full information
- ✅ Search functionality for products
- ✅ Pull-to-refresh on menu page

### Phase 4: Image Handling (Builds #17-19)
- ✅ HTTP to HTTPS URL conversion for all images
- ✅ Secure URL getters in models:
  - `Product.secureProductPic`
  - `StoreInfo.secureLogoUrl`
  - `StoreInfo.secureLandingPageUrl`
- ✅ `WebSafeImage` widget created (Build #19):
  - Shows loading spinner during image load
  - Graceful fallback to icons on error
  - Disabled caching to reduce CORS issues
  - Configurable placeholder and error widgets
- ✅ CORS issue resolved by server team

### Phase 5: Hierarchical Categories (Builds #20-21)
- ✅ Subcategory support (Build #20):
  - Parent categories can have child subcategories
  - Subcategories display in separate row with orange styling
  - Visual distinction between parent and subcategories
  - State management for parent/subcategory selection
- ✅ Auto-select first subcategory (Build #21):
  - When parent has no products, automatically selects first subcategory
  - When parent has products, shows them with subcategories available
  - Improved UX for category navigation

### Phase 6: UI Refinements (Build #22)
- ✅ Fixed product card layout for multi-line product names
- ✅ Price always visible regardless of name length
- ✅ Proper spacing and flexible layout

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart          # API endpoints and headers
│   │   └── storage_keys.dart           # SharedPreferences keys
│   └── utils/
│       └── md5_helper.dart             # MD5 signature generation
├── data/
│   ├── datasources/
│   │   ├── menu_remote_datasource.dart # Menu & product APIs
│   │   └── store_remote_datasource.dart # Store locator APIs
│   ├── models/
│   │   ├── menu_model.dart             # MenuCategory with subcategories
│   │   ├── product_model.dart          # Product with secure URLs
│   │   ├── store_credentials_model.dart # API credentials
│   │   └── store_info_model.dart       # Store information
│   └── repositories/
│       ├── menu_repository_impl.dart   # Menu repository with caching
│       └── store_repository_impl.dart  # Store repository with caching
├── presentation/
│   ├── bloc/
│   │   ├── menu_bloc.dart              # Menu state management
│   │   ├── menu_event.dart             # Menu events
│   │   ├── menu_state.dart             # Menu states
│   │   ├── store_bloc.dart             # Store state management
│   │   ├── store_event.dart            # Store events
│   │   └── store_state.dart            # Store states
│   ├── pages/
│   │   ├── home_page.dart              # Landing page
│   │   ├── menu_page.dart              # Menu with categories & products
│   │   ├── product_detail_page.dart    # Product details
│   │   └── store_locator_page.dart     # Store information display
│   └── widgets/
│       └── web_safe_image.dart         # Image widget with error handling
├── app.dart                            # GoRouter configuration
└── main.dart                           # App entry point (Build #22)
```

---

## 🔧 Technical Implementation Details

### API Authentication
- **Method:** MD5 signature-based authentication
- **Required Headers:**
  - `tenantId`, `time`, `sign`, `appKey`, `serialNumber`
  - `saleChannel: APP`, `updateChannel: APP`
- **Signature Format:** `MD5(appKey + uri + body + appSecret + timestamp)`

### State Management
- **Pattern:** BLoC (Business Logic Component)
- **Store BLoC:** Manages store locator flow
- **Menu BLoC:** Manages menu categories, products, search, filtering
- **Events:** LoadMenu, SelectCategory, SearchProducts, RefreshMenu
- **States:** Initial, Loading, Loaded, Error

### Data Caching
- **Storage:** SharedPreferences (browser localStorage)
- **Cached Data:**
  - Store credentials (appKey, appSecret, deviceId, etc.)
  - Store information (name, ID, logo URLs)
  - Menu categories
  - Products list
- **Cache Keys:** Defined in `storage_keys.dart`

### Category Structure
```dart
MenuCategory {
  int id
  int parentId              // 0 for parent categories
  String catName            // JSON: {"en": "...", "cn": "..."}
  List<MenuCategory> child  // Subcategories

  // Computed properties
  bool isParent => parentId == 0
  bool hasChildren => child.isNotEmpty
  String catNameEn          // Parsed English name
  String catNameCn          // Parsed Chinese name
}
```

### Menu Selection Logic
1. **"All" button:** Shows all products, clears selection
2. **Parent category with children, no products:**
   - Shows subcategories
   - Auto-selects first subcategory
   - Shows first subcategory's products
3. **Parent category with children, has products:**
   - Shows subcategories
   - Shows parent's products
   - User can select subcategory
4. **Parent category without children:**
   - Shows products directly

---

## 🎨 UI/UX Features

### Navigation Flow
```
Home (/)
  → QR Scan (/locate/:storeId)
    → Store Info Display
      → Menu (/menu)
        → Product Detail
```

### Color Scheme
- **Primary:** Orange (#FF9800)
- **Secondary Orange:** Orange[700] for subcategories
- **Success:** Green (Add button)
- **Error:** Red

### Responsive Design
- 2-column product grid on all screen sizes
- Horizontal scrollable category chips
- Fixed aspect ratio (1:1) product images
- Flexible card height (aspect ratio 0.75)

---

## 🧪 Testing

### Test Files
- `test/real_api_test.dart` - Real API integration tests
  - Store locator API test
  - Menu API test
  - Product API test
- `test/data/models/` - Model unit tests
- `test/presentation/bloc/` - BLoC unit tests
- `integration_test/` - Integration tests

### Test Store
- **Store ID:** `81898903-e31a-442a-9207-120e4a8f2a09`
- **Actual Store ID after lookup:** `12`
- **Categories:** 4 (Local Delights, Asian Favourites, Noodles, Local Beverages)
- **Subcategories:** Local Beverages → Cold Drinks, Hot Drinks
- **Products:** 64 active products

---

## 📊 Build History

| Build | Description | Key Changes |
|-------|-------------|-------------|
| #1-8 | Initial Setup | Project foundation, routing, theme |
| #9-15 | Store Locator | API integration, BLoC, caching |
| #16 | Menu Display | Menu categories, product grid |
| #17 | Image Security | HTTP to HTTPS conversion |
| #18 | Debug Cleanup | Removed console logging |
| #19 | Image Widget | WebSafeImage with loading states |
| #20 | Subcategories | Hierarchical category support |
| #21 | Auto-selection | Auto-select first subcategory |
| #22 | Layout Fix | Fixed price visibility issue |

---

## 🐛 Known Issues & Limitations

### Current Limitations
1. **Cart functionality not implemented** - "Add" button shows snackbar only
2. **Product modifiers not handled** - No combo products or customization
3. **No payment integration** - Ordering flow incomplete
4. **No authentication** - User login/signup not implemented
5. **No order history** - Past orders not tracked

### CORS Notes
- CORS issue with `oss.jeffy.sg` was **resolved by server team**
- Images now load successfully from `https://oss.jeffy.sg/toastho/images/`
- `WebSafeImage` widget provides graceful fallbacks for any future issues

---

## 📝 API Endpoints Used

### Store Locator APIs
```
POST https://api.jeffy.sg/locateStoreById
POST https://api.jeffy.sg/getStoreByDeviceNo
```

### Menu APIs
```
POST https://api.jeffy.sg/getMenu
POST https://api.jeffy.sg/getProductByStore
```

---

## 🚀 Next Steps / TODO

### High Priority
1. **Cart Implementation**
   - Cart state management (BLoC)
   - Add/remove products
   - Quantity adjustment
   - Cart page UI
   - Persist cart in SharedPreferences

2. **Product Modifiers & Combos**
   - Parse modifier data from API
   - Handle combo products
   - Customization UI (similar to React app's modal approach)
   - Price calculation with modifiers

3. **Checkout Flow**
   - Order summary page
   - Payment method selection
   - Order submission API
   - Order confirmation page

### Medium Priority
4. **User Authentication**
   - Login/signup pages
   - OTP verification
   - User profile management
   - Store user token

5. **Order History**
   - Past orders API integration
   - Order history page
   - Order tracking
   - Reorder functionality

6. **Additional Features**
   - Table number input/selection
   - Delivery vs Dine-in selection
   - Special instructions for orders
   - Promo code support

### Low Priority
7. **Polish & Optimization**
   - Loading skeletons instead of spinners
   - Image optimization/caching strategy
   - Performance improvements
   - Error boundary implementation
   - Analytics integration

---

## 🔄 Migration Notes (React → Flutter)

### Completed Migrations
- ✅ Store locator flow
- ✅ Menu display with categories
- ✅ Product grid display
- ✅ Hierarchical categories (parent/child)
- ✅ Auto-select subcategory logic

### Still in React App (Not Migrated)
- ❌ Cart management
- ❌ Product customization modal
- ❌ Combo product selection
- ❌ Modifier selection
- ❌ Checkout flow
- ❌ Payment integration
- ❌ User authentication
- ❌ Order history
- ❌ Redeemable products

### React Code References
- React app location: `/var/www/orderuat.jeffy.sg/src/`
- Key files to reference:
  - `component/AddToCart.js` - Product customization logic
  - `component/StoreLanding.js` - Category/subcategory handling
  - `component/Cart.js` - Cart management
  - `component/Payment.js` - Checkout flow

---

## 📞 Development Context

### Testing Access
- **UAT URL:** `https://mobileorderuat.jeffy.sg`
- **Test QR Code URL:** `https://mobileorderuat.jeffy.sg/locate/81898903-e31a-442a-9207-120e4a8f2a09`
- **React App (Reference):** `https://orderuat.jeffy.sg`

### Build Commands
```bash
# Development
flutter run -d chrome

# Build for production
flutter build web

# Run tests
flutter test
flutter test test/real_api_test.dart

# Analyze code
flutter analyze
```

### Deployment
- Build output: `build/web/`
- Deploy build/web contents to web server
- Ensure web server supports clean URLs (no #)

---

## 💡 Important Design Decisions

1. **BLoC over Provider:** Chosen for better separation of concerns and testability
2. **Clean URLs:** Using `url_strategy` package to remove # from URLs
3. **Repository Pattern:** Data layer abstraction for easier testing and API changes
4. **Model-first approach:** Strong typing with dedicated model classes
5. **Secure URLs by default:** All image URLs converted to HTTPS in model getters
6. **Auto-select subcategories:** Better UX when parent categories are just containers
7. **WebSafeImage widget:** Centralized image handling with consistent error states

---

## 📄 Related Documentation

- `PROJECT_OVERVIEW.md` - High-level project description
- `IMPLEMENTATION_PLAN.md` - Original implementation plan
- `API_DOCUMENTATION.md` - API endpoint details
- `README.md` - Setup and running instructions

---

**End of Progress Report - Ready for next phase of development**
