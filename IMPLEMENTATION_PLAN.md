# Jeffy Mobile Order - Implementation Plan (Quick Service MVP)

## MVP Scope

### ✅ INCLUDED Features (Quick Service MVP)
1. **Store Locator** - Quick Service only (single GUID `/locate/{storeId}`)
2. **Authentication** - Login (phone + PIN), Guest mode, OTP, PDPA, Registration
3. **Menu Browsing** - Categories, products, simple modifiers only
4. **Shopping Cart** - Add, remove, update quantities, persist to localStorage
5. **Sales Type** - Takeaway & Pickup only (no dine-in)
6. **Payment** - Credit card via gateway + Pay at Counter
7. **Order Confirmation** - Success/error/timeout/cancel screens
8. **Basic Profile** - View user info + Logout
9. **Static Pages** - T&C, Privacy Policy, Refund Policy

### ❌ EXCLUDED Features (For Later Implementation)
- ~~All Loyalty/CRM~~ (Advocado cashback, stored value, prepaid, redemption PIN, top-up)
- ~~Table Service~~ (Implement after Quick Service MVP is complete)
- ~~Order History~~ (Implement after Table Service)
- ~~Combo Products~~ (Not at this stage - simple products only)
- ~~Staff Discount~~ (Not needed for MVP)
- ~~Vouchers/Coupons~~ (Not needed for MVP)
- ~~Product Search~~ (Browse by category is sufficient)
- ~~Multi-language~~ (English only for now)
- ~~Edit Profile / Change PIN~~ (View only)
- ~~Feedback Form~~ (Add later)

### Estimated Timeline
**4-5 weeks** instead of 8 weeks (simplified scope)

---

## Implementation Philosophy

This plan follows an **incremental, testable approach**:
- Start with the most basic functionality
- Test each phase thoroughly before proceeding
- Build complexity gradually
- Ask for clarification when needed

Each phase has clear **Completion Criteria** that must be verified before moving to the next phase.

---

## Phase 1: Project Setup & Basic Flutter Web (Days 1-2)

### Objectives
- Initialize Flutter web project
- Set up basic dependencies
- Create minimal app structure
- Verify Flutter web runs in browser

### Tasks

#### 1.1 Initialize Flutter Project
```bash
cd /var/www/mobileorder.jeffy.sg
flutter create --platforms web .
flutter config --enable-web
```

#### 1.2 Configure pubspec.yaml
Add basic dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  getwidget: ^4.0.0
  go_router: ^12.0.0
  url_strategy: ^0.2.0
```

#### 1.3 Create Basic App Structure
```
lib/
├── main.dart          # App entry point
└── app.dart           # Root app widget
```

#### 1.4 Implement main.dart
- Remove # from URLs (setPathUrlStrategy)
- Run MaterialApp with basic route

#### 1.5 Test Basic Setup
```bash
flutter pub get
flutter run -d chrome
```

### Completion Criteria
- [ ] Flutter web project initialized
- [ ] App runs in Chrome browser
- [ ] Can access http://localhost:port
- [ ] Shows basic "Hello World" screen
- [ ] No compilation errors

### Testing
- Open browser to localhost
- Verify page loads
- Check browser console for errors

---

## Phase 2: Router Setup with GUID Extraction (Days 3-4)

### Objectives
- Set up GoRouter with URL parameters
- Create store locator route with GUID extraction
- Test URL parameter parsing

### Tasks

#### 2.1 Create Router Configuration
```
lib/
├── core/
│   └── config/
│       └── routes/
│           └── app_router.dart
```

#### 2.2 Implement Routes
- `/locate/:storeId` - Quick service route (MVP)
- `/locate/:storeId/:sessionId` - Table service route (SKIP FOR NOW - Future)
- Test route (temporary)

**Note:** Only implement Quick Service route for MVP. Table service will be added later.

#### 2.3 Create Simple Store Locator Screen
```
lib/
├── features/
│   └── store_locator/
│       └── ui/
│           └── store_locator_screen.dart
```

Display extracted GUIDs on screen (text only)

#### 2.4 Update app.dart
Connect GoRouter to MaterialApp.router

### Completion Criteria
- [ ] Can navigate to `/locate/test-guid-123`
- [ ] Screen displays: "Store ID: test-guid-123"
- [ ] Browser URL bar shows clean URLs (no #)

**Note:** Table service route (`/locate/guid1/guid2`) will be implemented later.

### Testing
Manual URL testing:
- http://localhost:port/locate/abc123
- Verify GUID is extracted and displayed

**Skip for MVP:** Table service URL testing

---

## Phase 3: Web Storage Service (Day 5)

### Objectives
- Implement localStorage wrapper
- Test saving and retrieving data
- Verify persistence across page refresh

### Tasks

#### 3.1 Add localstorage Dependency
```yaml
dependencies:
  localstorage: ^4.0.1+4
```

#### 3.2 Create Storage Service
```
lib/
├── core/
│   └── storage/
│       └── web_storage_service.dart
```

Implement methods:
- `saveStoreId(String id)`
- `getStoreId()`
- `saveData(String key, dynamic value)`
- `getData(String key)`
- `clearAll()`

#### 3.3 Test Storage in Store Locator Screen
- Save extracted GUID to localStorage
- Display saved value
- Add "Clear Storage" button

### Completion Criteria
- [ ] Can save GUID to localStorage
- [ ] Can retrieve GUID from localStorage
- [ ] Data persists after page refresh
- [ ] Can clear localStorage
- [ ] Browser DevTools shows localStorage entry

### Testing
1. Navigate to `/locate/test123`
2. Refresh page - verify GUID persists
3. Click "Clear" - verify GUID is removed
4. Open browser DevTools → Application → Local Storage
5. Verify entries are present/absent

---

## Phase 4: API Client Setup (Days 6-7)

### Objectives
- Set up Dio HTTP client
- Implement MD5 request signing
- Test API call to locateStoreById

### Tasks

#### 4.1 Add Dependencies
```yaml
dependencies:
  dio: ^5.3.3
  crypto: ^3.0.3
  pretty_dio_logger: ^1.3.1
```

#### 4.2 Create API Client
```
lib/
├── core/
│   └── network/
│       ├── api_client.dart
│       └── api_interceptor.dart
```

#### 4.3 Implement locateStoreById API Call
```
lib/
├── features/
│   └── store_locator/
│       └── data/
│           └── repositories/
│               └── store_repository.dart
```

**Important:** Need API endpoint details from React app:
- What is the exact endpoint URL?
- What is the request format?
- What is the response format?

#### 4.4 Test API Call
Update store locator screen to:
- Call real API with extracted GUID
- Display API response
- Handle errors

### Completion Criteria
- [ ] Can make HTTP request to API
- [ ] Request includes MD5 signature headers
- [ ] Receives response from API
- [ ] Can handle API errors gracefully
- [ ] Response data displayed on screen

### Testing
1. Navigate to `/locate/{real-store-guid}`
2. Check browser Network tab
3. Verify request headers include signature
4. Verify response received
5. Display response data on screen

**Before proceeding:** Need to confirm:
- API base URL
- API endpoint format
- Sample response structure

---

## Phase 5: Store Configuration Models & State (Days 8-9)

### Objectives
- Create data models for API responses
- Implement BLoC for store locator
- Save store config to localStorage
- Display store information

### Tasks

#### 5.1 Add Dependencies
```yaml
dependencies:
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  freezed_annotation: ^2.4.1

dev_dependencies:
  build_runner: ^2.4.6
  json_serializable: ^6.7.1
  freezed: ^2.4.5
```

#### 5.2 Create Models
```
lib/
├── features/
│   └── store_locator/
│       └── data/
│           └── models/
│               ├── store_config_model.dart
│               └── store_info_model.dart
```

**Need from React app:**
- Exact JSON response structure from locateStoreById
- Required fields

#### 5.3 Implement StoreLocatorBloc
```
lib/
├── features/
│   └── store_locator/
│       └── bloc/
│           ├── store_locator_bloc.dart
│           ├── store_locator_event.dart
│           └── store_locator_state.dart
```

States:
- Initial
- Loading
- Success (with store config)
- Error

#### 5.4 Update Store Locator Screen
- Use BlocProvider and BlocBuilder
- Show loading indicator
- Display store info on success
- Show error message on failure

### Completion Criteria
- [ ] Models generated with build_runner
- [ ] BLoC receives GUID and calls API
- [ ] Loading state shows spinner
- [ ] Success state displays store name, logo
- [ ] Error state shows error message
- [ ] Store config saved to localStorage

### Testing
1. Navigate to `/locate/{valid-guid}`
2. See loading spinner
3. See store name and info
4. Check localStorage for saved config
5. Navigate to `/locate/invalid-guid`
6. See error message

---

## Phase 6: Navigation After Store Locator (Days 10-11)

### Objectives
- Add authentication routes
- Create basic login screen
- Navigate from store locator to login
- Implement route guards

### Tasks

#### 6.1 Add Authentication Routes
In app_router.dart:
- `/auth/login`
- `/home` (placeholder)

#### 6.2 Create Basic Login Screen
```
lib/
├── features/
│   └── auth/
│       └── ui/
│           └── login_screen.dart
```

Simple screen with:
- GetWidget card
- "Login" title
- Button to navigate to home
- Back button

#### 6.3 Update Store Locator Navigation
After successful API call:
- If user already logged in → navigate to `/home`
- If not logged in → navigate to `/auth/login`

#### 6.4 Create Placeholder Home Screen
```
lib/
├── features/
│   └── home/
│       └── ui/
│           └── home_screen.dart
```

Display:
- Store name from localStorage
- "Welcome to {store name}"

#### 6.5 Add Route Guards
Protect routes that need store config:
- Redirect to error if accessing `/home` without store config

### Completion Criteria
- [ ] Can navigate from store locator to login
- [ ] Can navigate from login to home
- [ ] Home screen displays store info from localStorage
- [ ] Cannot access `/home` directly without store config
- [ ] Browser back button works correctly

### Testing
1. Access `/locate/{guid}` → redirects to `/auth/login`
2. Click "Continue" → goes to `/home`
3. Home shows store name
4. Try accessing `/home` directly in new tab → redirected
5. Browser back/forward buttons work

---

## Phase 7: Authentication UI with GetWidget (Days 12-14)

### Objectives
- Create proper login form with GetWidget components
- Implement form validation
- Test UI responsiveness

### Tasks

#### 7.1 Build Login Form
Use GetWidget components:
- `GFCard` - Form container
- `GFDropdown` - Country code selector
- `GFTextField` - Phone number input
- `GFTextField` - PIN input (obscureText)
- `GFButton` - Login button
- `GFButton` (outline) - Guest mode button

#### 7.2 Implement Form Validation
- Phone: 8 digits, numbers only
- PIN: 6 digits, numbers only
- Show validation errors with GFAlert

#### 7.3 Add Responsive Layout
```
lib/
├── shared/
│   └── widgets/
│       └── responsive/
│           └── responsive_layout.dart
```

- Mobile: Full width form
- Desktop: Centered card (max 500px)

#### 7.4 Create Loading State
- Show GFLoader when submitting
- Disable buttons during loading

### Completion Criteria
- [ ] Login form displays correctly on mobile
- [ ] Login form displays correctly on desktop
- [ ] Phone validation works
- [ ] PIN validation works
- [ ] Error messages show with GFAlert
- [ ] Loading state shows GFLoader
- [ ] Form is visually appealing

### Testing
1. Resize browser (mobile → desktop)
2. Enter invalid phone → see error
3. Enter valid inputs
4. Click login → see loading spinner
5. Test on actual mobile browser

---

## Phase 8: Authentication API Integration (Days 15-17)

### Objectives
- Implement userLogin API call
- Create AuthBloc
- Handle login success/failure
- Save user info to localStorage

### Tasks

#### 8.1 Create Auth Repository
```
lib/
├── features/
│   └── auth/
│       └── data/
│           ├── models/
│           │   └── user_model.dart
│           └── repositories/
│               └── auth_repository.dart
```

Implement:
- `login(countryCode, mobile, password)`
- `guestLogin()`

**Need from React app:**
- userLogin API endpoint
- Request format
- Response format

#### 8.2 Create AuthBloc
```
lib/
├── features/
│   └── auth/
│       └── bloc/
│           ├── auth_bloc.dart
│           ├── auth_event.dart
│           └── auth_state.dart
```

Events:
- LoginRequested
- GuestLoginRequested
- LogoutRequested

States:
- Unauthenticated
- Authenticating
- Authenticated (with user info)
- AuthError

#### 8.3 Update Login Screen
- Connect to AuthBloc
- Call login on button press
- Navigate to home on success
- Show error on failure
- Save user info to localStorage

#### 8.4 Update Home Screen
- Display user info if logged in
- Show guest message if guest mode
- Add logout button

### Completion Criteria
- [ ] Can login with valid credentials
- [ ] User info saved to localStorage
- [ ] Navigate to home after login
- [ ] Invalid credentials show error
- [ ] Guest mode works
- [ ] Can logout and return to login
- [ ] User info persists after page refresh

### Testing
1. Enter valid credentials → login success → see home
2. Enter invalid credentials → see error
3. Click guest mode → see home with guest message
4. Refresh page → still logged in
5. Logout → return to login screen

---

## Phase 9: Menu API Integration (Days 18-21)

### Objectives
- Fetch menu data from API
- Display categories
- Display products
- Basic navigation between categories

### Tasks

#### 9.1 Create Menu Repository
```
lib/
├── features/
│   └── menu/
│       └── data/
│           ├── models/
│           │   ├── category_model.dart
│           │   └── product_model.dart
│           └── repositories/
│               └── menu_repository.dart
```

API calls needed:
- `getMenu(storeId)`
- `getProductByStore(storeId)`
- `getProductAtt(storeId)`

**Need from React app:**
- API endpoints
- Response structures
- How categories and products are related

#### 9.2 Create MenuBloc
```
lib/
├── features/
│   └── menu/
│       └── bloc/
│           ├── menu_bloc.dart
│           ├── menu_event.dart
│           └── menu_state.dart
```

#### 9.3 Update Home Screen
- Fetch menu data on load
- Display main categories (horizontal scroll)
- Display products in grid
- Use GetWidget components:
  - `GFCard` for category items
  - `GFCard` for product items
  - `GFImageOverlay` for images

#### 9.4 Add Loading & Error States
- Show `GFShimmer` while loading
- Show error message if API fails
- Pull-to-refresh functionality

### Completion Criteria
- [ ] Menu data fetched from API
- [ ] Categories displayed horizontally
- [ ] Products displayed in grid (2 columns mobile)
- [ ] Category selection filters products
- [ ] Images load and display
- [ ] Loading shimmer shows during fetch
- [ ] Error handling works

### Testing
1. Login and navigate to home
2. See categories loading with shimmer
3. See categories appear
4. Click category → see products
5. Scroll products → smooth scrolling
6. Pull to refresh → reloads data

---

## Phase 10: Product Details & Modifiers (Days 22-25)

### Objectives
- Create product detail screen/modal
- Display product modifiers
- Handle modifier selection
- Calculate price with modifiers

### Tasks

#### 10.1 Create Product Detail Screen
```
lib/
├── features/
│   └── menu/
│       └── ui/
│           └── product_detail_screen.dart
```

#### 10.2 Display Modifiers (Simple Only)
- Parse modifier data from API
- Single-select modifiers: `GFRadioListTile`
- Multi-select modifiers: `GFCheckboxListTile`
- Group modifiers: `GFAccordion`

**MVP Scope:** Simple modifiers only
- **INCLUDE:** Size, temperature, add-ons (simple)
- **EXCLUDE:** Complex combo products

See `API_DOCUMENTATION.md` for modifier structure details.

#### 10.3 Price Calculation
- Base product price
- Add modifier prices
- Display total at bottom

#### 10.4 Quantity Selector
- Minus/Plus buttons
- Quantity display
- Minimum quantity: 1

#### 10.5 Add to Cart Button
- Sticky bottom button
- "Add to Cart" with total price
- Validation (required modifiers selected)

### Completion Criteria
- [ ] Product detail shows when clicking product
- [ ] Modifiers display correctly
- [ ] Can select/deselect modifiers
- [ ] Price updates in real-time
- [ ] Quantity changes work
- [ ] Add to cart button shows total
- [ ] Validation prevents incomplete selections

### Testing
1. Click product → opens detail
2. Select modifiers → price updates
3. Change quantity → price updates
4. Try to add without required modifier → validation error
5. Successfully add to cart → confirmation

---

## Phase 11: Shopping Cart (Days 26-29)

### Objectives
- Implement cart state management
- Create cart screen
- Cart persistence in localStorage
- Cart operations (add, remove, update)

### Tasks

#### 11.1 Create CartBloc
```
lib/
├── features/
│   └── cart/
│       └── bloc/
│           ├── cart_bloc.dart
│           ├── cart_event.dart
│           └── cart_state.dart
```

Events:
- AddToCart
- RemoveFromCart
- UpdateQuantity
- ClearCart

#### 11.2 Create Cart Models
```
lib/
├── features/
│   └── cart/
│       └── data/
│           └── models/
│               └── cart_item_model.dart
```

Cart item includes:
- Product info
- Selected modifiers
- Quantity
- Total price

#### 11.3 Update Product Detail
- Connect to CartBloc
- Add to cart on button press
- Show success feedback (GFToast)
- Navigate back

#### 11.4 Create Cart Screen
```
lib/
├── features/
│   └── cart/
│       └── ui/
│           └── cart_screen.dart
```

Components:
- List of cart items (GFCard)
- Item details with modifiers
- Quantity controls
- Delete button (GFIconButton)
- Order summary card
- Checkout button

#### 11.5 Add Cart Badge
- Update app bar with cart icon
- Show badge with item count
- Navigate to cart on click

#### 11.6 Cart Persistence
- Save cart to localStorage on changes
- Load cart on app start

### Completion Criteria
- [ ] Can add product to cart
- [ ] Cart badge shows item count
- [ ] Cart screen displays all items
- [ ] Can change quantity in cart
- [ ] Can remove items from cart
- [ ] Order summary calculates correctly
- [ ] Cart persists after page refresh
- [ ] Empty cart shows empty state

### Testing
1. Add product to cart → see badge update
2. Click cart icon → see cart screen
3. See product with modifiers
4. Change quantity → price updates
5. Delete item → item removed
6. Refresh page → cart persists
7. Empty cart → see empty state

---

## Phase 12: Sales Type Selection - Quick Service Only (Days 30-31)

### Objectives
- Create sales type screen
- Quick Service: Takeaway & Pickup only
- Collect pickup time

### Tasks

#### 12.1 Create Sales Type Screen
```
lib/
├── features/
│   └── order/
│       └── ui/
│           └── sales_type_screen.dart
```

#### 12.2 Sales Type Options (MVP: Quick Service Only)
Using GFCard components:
- **Takeaway** (MVP)
- **Pickup** (MVP)

**EXCLUDED for MVP:**
- ~~Dine-in~~ (Table service - future)
- ~~Delivery~~ (Add if needed later)

#### 12.3 Additional Info Collection
- Pickup time (time selector for takeaway/pickup)

#### 12.4 Navigation
- From cart → sales type → payment
- Save selected type to order state

### Completion Criteria
- [ ] Sales type screen displays Takeaway & Pickup options
- [ ] Can select sales type
- [ ] Pickup time selector works
- [ ] Continue button navigates to payment

### Testing
1. From cart click checkout
2. See sales type options (Takeaway & Pickup)
3. Select takeaway → select pickup time
4. Continue → proceed to payment

**Skip for MVP:** Table service / dine-in testing

---

## Phase 13: Payment Screen UI (Days 32-34)

### Objectives
- Create payment method selection screen
- Display order summary
- Handle payment method validation

### Tasks

#### 13.1 Create Payment Screen
```
lib/
├── features/
│   └── payment/
│       └── ui/
│           └── payment_screen.dart
```

#### 13.2 Payment Methods (MVP: Basic Only)
Using GFRadioListTile:
- **Pay by Credit Card** (via payment gateway)
- **Pay at Counter**

**EXCLUDED for MVP:**
- ~~Loyalty payments~~ (Advocado, cashback, stored value, prepaid)
- ~~Redemption PIN~~ (Not needed without loyalty)

#### 13.3 Order Summary
- Sticky summary card
- Line items
- Subtotal
- Service charge
- Total

#### 13.4 ~~Staff Discount & Vouchers~~ (EXCLUDED for MVP)
**Skip for MVP** - Not needed for initial version

#### 13.5 Confirm Payment Button
- Validate payment method selected
- Navigate to processing

### Completion Criteria
- [ ] Payment screen displays
- [ ] Order summary shows all items
- [ ] Can select payment method (Credit Card or Pay at Counter)
- [ ] Total calculates correctly
- [ ] Confirm button validation works

### Testing
1. From sales type → payment screen
2. See order summary
3. Select payment method (Credit Card or Pay at Counter)
4. Click confirm → validation works

**Skip for MVP:** Staff discount, vouchers, loyalty payments

---

## Phase 14: Payment Gateway Integration (Days 35-38)

### Objectives
- Integrate Mastercard Payment Gateway
- Submit order to backend
- Handle payment flow
- Create success/error screens

### Tasks

#### 14.1 Add Payment Gateway Script
In `web/index.html`:
```html
<script src="https://payment-gateway-url/checkout.js"></script>
```

**Need:**
- Exact payment gateway script URL
- Test vs production URLs

#### 14.2 Create JS Interop
```
lib/
├── core/
│   └── utils/
│       └── payment_gateway_interop.dart
```

```dart
@JS('Checkout.configure')
external void configureCheckout(dynamic config);

@JS('Checkout.showPaymentPage')
external void showPaymentPage();
```

#### 14.3 Implement Order Submission
```
lib/
├── features/
│   └── payment/
│       └── data/
│           └── repositories/
│               └── payment_repository.dart
```

API call:
- `mobileOrderRequest(orderData)`

**Need from React app:**
- Order request format
- Required fields
- Response format with sessionID

#### 14.4 Payment Flow
1. User clicks confirm
2. Submit order → get sessionID
3. Configure payment gateway
4. Show payment page
5. User completes payment
6. Gateway redirects back
7. Call paymentUpdate()
8. Show success/error screen

#### 14.5 Create Result Screens
```
lib/
├── features/
│   └── payment/
│       └── ui/
│           ├── payment_success_screen.dart
│           ├── payment_error_screen.dart
│           └── payment_processing_screen.dart
```

### Completion Criteria
- [ ] Can submit order to API
- [ ] Receives sessionID
- [ ] Payment gateway opens
- [ ] Can complete test payment
- [ ] Gateway redirects back to app
- [ ] Success screen shows order details
- [ ] Error handling works

### Testing
1. Complete order flow
2. Click confirm payment
3. See processing screen
4. Payment gateway opens
5. Complete payment (test card)
6. Redirected back
7. See success screen with order number

**Before proceeding:** Need:
- Payment gateway test credentials
- Test card numbers
- Return URL configuration

---

## ~~Phase 15: Order History~~ (EXCLUDED - Implement After Table Service)

**Status:** Deferred to post-MVP

This feature will be implemented after Table Service is complete.

---

## Phase 15: User Profile (Days 39-40) - Simplified MVP Version

### Objectives
- Create basic profile screen
- Display user info
- Logout functionality only

### Tasks

#### 15.1 Create Profile Screen
```
lib/
├── features/
│   └── profile/
│       └── ui/
│           └── profile_screen.dart
```

#### 15.2 Display User Info (Read-Only)
- Name, phone, email
- GFAvatar with initials
- Simple display (no editing for MVP)

#### 15.3 Logout
- Clear localStorage
- Clear BLoC states
- Navigate to login

### Completion Criteria
- [ ] Profile screen displays user info
- [ ] Logout clears data and redirects

### Testing
1. Navigate to profile from side menu
2. See user information
3. Click logout
4. Verify localStorage cleared
5. Redirected to login

**EXCLUDED for MVP:**
- ~~Edit profile~~ (Future)
- ~~Change PIN~~ (Future)
- ~~Loyalty balances~~ (No loyalty in MVP)

---

## Phase 16: Static Pages (Days 41-42)

### Objectives
- Create T&C, Privacy, Refund Policy pages
- Create feedback form

### Tasks

#### 17.1 Create Static Pages
```
lib/
├── features/
│   └── static_pages/
│       └── ui/
│           ├── tnc_screen.dart
│           ├── privacy_screen.dart
│           └── refund_policy_screen.dart
```

#### 17.2 Content Display
- Fetch content from API or hardcode
- Display in scrollable GFCard
- Formatted text

#### 16.3 ~~Feedback Form~~ (EXCLUDED for MVP)
**Skip for MVP** - Add in future version

### Completion Criteria
- [ ] T&C page displays content
- [ ] Privacy Policy page displays content
- [ ] Refund Policy page displays content

**EXCLUDED:** Feedback form (add later)

---

## Phase 17: Polish & Optimization (Days 43-45)

### Objectives
- Improve UI/UX
- Add animations
- Optimize performance
- Fix bugs

### Tasks

#### 18.1 UI Improvements
- Add page transitions
- Improve loading states with GFShimmer
- Add success animations (Lottie)
- Improve error messages

#### 18.2 Performance
- Image caching
- Lazy loading
- Code splitting
- Reduce bundle size

#### 18.3 Responsive Design
- Test all screens on different sizes
- Improve desktop layouts
- Fix mobile issues

#### 18.4 Error Handling
- Network error recovery
- Better error messages
- Retry functionality

### Completion Criteria
- [ ] All screens responsive
- [ ] Smooth animations
- [ ] Fast load times
- [ ] No critical bugs

---

## Phase 18: Testing & Bug Fixes (Days 46-48)

### Objectives
- Comprehensive testing
- Fix all bugs
- Cross-browser testing

### Tasks

#### 18.1 Functional Testing (MVP Scope Only)
- Test complete user journey
- Quick service flow (Takeaway & Pickup)
- Guest mode
- Credit card payment
- Pay at counter

**EXCLUDED from testing:**
- ~~Table service~~
- ~~Loyalty payments~~

#### 19.2 Browser Testing
- Chrome
- Safari
- Firefox
- Mobile browsers

#### 19.3 Edge Cases
- Offline handling
- Invalid data
- API failures
- Payment failures

#### 19.4 Bug Fixes
- Fix identified issues
- Retest after fixes

### Completion Criteria
- [ ] All critical bugs fixed
- [ ] Works on all browsers
- [ ] Complete flows tested
- [ ] Ready for deployment

---

## Phase 19: Deployment Preparation (Days 49-50)

### Objectives
- Build production version
- Optimize for production
- Deployment documentation

### Tasks

#### 20.1 Production Build
```bash
flutter build web --release --web-renderer canvaskit
```

#### 20.2 Optimization
- Minification
- Tree shaking
- Asset optimization

#### 20.3 Deployment
- Copy build/web/* to server directory
- Test production build locally
- Configure production API URLs

#### 20.4 Documentation
- Deployment guide
- User manual
- Admin guide

### Completion Criteria
- [ ] Production build successful
- [ ] Build tested locally
- [ ] Ready for deployment
- [ ] Documentation complete

---

## Questions to Clarify Before Starting

### API Details Needed:
1. **locateStoreById API:**
   - Endpoint URL format
   - Request headers required
   - Response JSON structure
   - Error response format

2. **Authentication APIs:**
   - userLogin endpoint and format
   - getOTP endpoint and format
   - Response structures

3. **Menu APIs:**
   - getMenu, getProductByStore, getProductAtt endpoints
   - Response structures
   - How are modifiers structured?
   - How are combo products structured?

4. **Order & Payment APIs:**
   - mobileOrderRequest format
   - paymentUpdate format
   - sessionID usage

5. **Payment Gateway:**
   - Gateway script URL (test and production)
   - Test credentials
   - Return URL configuration

### Design Decisions (ANSWERED):
1. Should we match React app's UI exactly or improve it? **✅ Improve it**
2. Which features are highest priority? **✅ See MVP Scope section above**
3. Any features we can skip initially? **✅ See EXCLUDED features section above**
4. Mobile-first or desktop-first design? **✅ Mobile-first**

### Infrastructure:
1. Is there a test API environment available? **See API_DOCUMENTATION.md - using orderuat.jeffy.sg**
2. Are there test store GUIDs we can use? **✅ Yes: `81898903-e31a-442a-9207-120e4a8f2a09`**
3. What is the deployment process? **User will handle nginx config manually**

---

## Next Steps

1. Review this implementation plan
2. Clarify questions above
3. Begin Phase 1: Project Setup
4. Test each phase thoroughly before proceeding

**Remember:** We will NOT implement everything at once. We will go phase by phase, testing at each stage to ensure everything works before moving forward.
