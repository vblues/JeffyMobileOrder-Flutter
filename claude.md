# Claude Development Notes

## Important Reminders

### Version/Build Number Updates

**ALWAYS update BOTH build numbers when making changes:**

1. **pubspec.yaml** (line 19):
   ```yaml
   version: 1.0.0+31
   ```

2. **lib/main.dart** (line 8):
   ```dart
   const kBuildNumber = '31'; // Build 31: Description of changes
   ```

**Process:**
- Increment the build number in both files simultaneously
- Add a descriptive comment in main.dart explaining what changed
- Build the app to ensure the new version is reflected

**Verification:**
After building, check browser console for:
```
============================================================
Mobile Order App Starting
Version: 1.0.0+31
Build: [timestamp]
============================================================
```

---

## Project Structure

### Key Files
- `lib/main.dart` - App entry point with version logging
- `lib/app.dart` - Root app widget with routing
- `lib/presentation/pages/` - UI pages
- `lib/presentation/bloc/` - BLoC state management
- `lib/data/models/` - Data models
- `lib/data/datasources/` - API data sources
- `lib/data/repositories/` - Repository pattern implementation
- `lib/core/` - Constants, utilities, helpers

### Current Build: 35
**What's included:**
- Phase 1: Project setup with Flutter web
- Phase 2: Store locator API integration
- Phase 3: Menu display with product modifiers
  - Product attribute models
  - Modifier selection UI with bottom sheets
  - Price calculation with modifiers
  - Validation for mandatory selections
  - Product detail image overlay shows only name and description (price removed)
  - Modifier popup: Live price badge in header, no additional cost summary at bottom
- Phase 3.5: Combo components (COMPLETE)
  - ✅ Combo data models (ComboActivity, ComboCategory, ComboProductInfo, SelectedComboItem)
  - ✅ API endpoints: getActivityComboWithPrice, getStoreComboProduct
  - ✅ MenuRepository with combo loading and caching
  - ✅ MenuBloc loads combo data alongside menu
  - ✅ MenuState includes combo information with helper methods
  - ✅ **Combo matching logic**: First category acts as matcher to identify products with combos
  - ✅ **Combo selection**: Only subsequent categories (index 1+) are presented for selection
  - ✅ Combo detection and pass to product detail page
  - ✅ Combo selection UI with bottom sheets (similar to modifiers)
  - ✅ Combo price calculation with adjustments (positive/negative)
  - ✅ Validation for mandatory combo selections
  - ✅ Radio buttons for single-select, checkboxes for multi-select
  - ✅ Live price adjustment badge in combo selection sheet

---

## Development Guidelines

### Before Each Build
1. ✅ Update version in pubspec.yaml
2. ✅ Update kBuildNumber in lib/main.dart
3. ✅ Clear browser cache after deployment
4. ✅ Verify version in console log

### Git Commit Best Practices
- Use descriptive commit messages
- Include build number in commit if UI changes
- Group related changes together
- Reference phase/feature in commit message

---

## API Notes

### Endpoints Implemented
- `GET /api/entry/getstoreinfo/{storeId}` - Store initialization
- `POST /api/mobile/getMenu` - Menu categories
- `POST /api/mobile/getProductByStore` - Products list
- `POST /api/mobile/getProductAtt` - Product attributes/modifiers
- `POST /api/mobile/getActivityComboWithPrice` - Combo activities with pricing
- `POST /api/mobile/getStoreComboProduct` - Combo products list

### Authentication
All API requests (except store locator) require MD5 signature:
- Headers: Tenant-Id, time, sign, appkey, Serial-Number
- Signature: md5(appKey + appSecret + uri + body + timestamp)

---

## Next Steps

### Phase 4 (Not Yet Implemented)
- Shopping cart functionality
  - Cart state management (BLoC)
  - Add/remove items from cart
  - Persist cart data locally
  - Display cart badge with item count
- Order submission
  - Order review page
  - Submit order API integration
  - Order confirmation
- Payment integration
  - Payment method selection
  - Payment gateway integration
  - Payment confirmation
