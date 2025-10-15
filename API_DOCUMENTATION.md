# API Documentation - Jeffy Mobile Ordering System

## Overview

This document provides comprehensive API documentation extracted from the React.js app at `/var/www/orderuat.jeffy.sg`. All endpoints use **POST** requests unless otherwise specified, and require MD5 signature authentication.

---

## Base URL & Configuration

### Dynamic Base URL
The API domain is dynamically configured per store via the `locateStoreById` endpoint.

```javascript
// From React app
baseURL = (window.location.hostname == 'localhost')
  ? 'http://' + window.location.host
  : 'https://' + window.location.host
```

### Store Locator Endpoint (GET - No Authentication Required)
```
GET https://mobile.jeffy.sg/api/entry/getstoreinfo/{storeId}
GET https://mobile.jeffy.sg/api/entry/getstoreinfo/{storeId}/{sessionId}
```

**Purpose:** Initialize app and get store credentials

**Example Response:** See `/docs/menu/getStoreByDeviceNo.json`

---

## Authentication & Request Signing

### Required Headers

Every API request (except `locateStoreById`) requires these headers:

```javascript
headers: {
  "Content-Type": "application/json",
  "Tenant-Id": "{credentials.tenantID}",
  "time": "{secondsSinceEpoch}",
  "sign": "{md5Signature}",
  "appkey": "{credentials.appKey}",
  "Serial-Number": "{credentials.deviceID}",
  "Sale-Channel": "APP",
  "Update-Channel": "APP"
}
```

### MD5 Signature Generation

```javascript
const secondsSinceEpoch = Math.round(new Date().getTime() / 1000);
const sign = md5(
  credentials.appKey +
  credentials.appSecret +
  uri +
  body +
  secondsSinceEpoch
).toString();
```

**Parameters:**
- `uri`: API endpoint path (e.g., "api/mobile/getMenu")
- `body`: Stringified JSON request body
- `secondsSinceEpoch`: Current Unix timestamp in seconds

---

## API Endpoints

### 1. Store Initialization

#### locateStoreById (GET)
**Endpoint:** `GET https://mobile.jeffy.sg/api/entry/getstoreinfo/{storeId}` or with `/{sessionId}`

**Purpose:** Get store configuration, credentials, and settings

**Request:** No body, no special headers

**Response Structure:**
```json
{
  "result_code": 200,
  "storeInfos": [
    {
      "store_id": 12,
      "store_sn": "003002",
      "store_name": "{\"cn\":\"Store CN\",\"en\":\"Store EN\"}",
      "store_note": "{JSON string containing extensive configuration}",
      "pay_platform": "23,60",
      "work_time": "{JSON with operating hours}"
    }
  ],
  "payTypeInfo": [...],
  "DeviceInfo": {
    "device_name": "SGH MO",
    "store_id": 12
  },
  "saleTypeInfo": [...],
  "desc": "success"
}
```

**Store Note Contains:**
- GST configuration
- CRM settings (Advocado campaigns)
- Sales type messages
- Payment type configurations
- Staff discount settings
- Pager settings
- Payment success/failure messages
- Landing page configuration
- Images for various states

**What to Store in localStorage:**
- Entire response → `STORE_CREDENTIALS`
- `storeInfos[0]` → `STORE_INFO`
- `storeInfos[0].store_id` → `STORE_ID`
- Extract from DeviceInfo:
  - `tenantID`
  - `appKey`
  - `appSecret`
  - `deviceID`
  - `apiDomain` (base URL for subsequent requests)

---

### 2. Menu & Product APIs

#### getMenu
**Endpoint:** `POST api/mobile/getMenu`

**Request:**
```json
{
  "store_id": 12,
  "redeemable": 0
}
```
- `redeemable`: 0 for normal menu, 1 for prepaid/redemption menu

**Response:** See `/docs/menu/getMenu.json`

```json
{
  "result_code": 200,
  "menu": [
    {
      "id": 105,
      "parent_id": 0,
      "cat_name": "{\"cn\":\"Toast Value Meal\",\"en\":\"Toast Value Meal\"}",
      "category_sn": "0004",
      "cat_pic": "http://oss.jeffy.sg/...",
      "sort_sn": 9,
      "child": [
        {
          "id": 106,
          "parent_id": 105,
          "cat_name": "{\"cn\":\"Crispy Toast Set\",\"en\":\"Crispy Toast Set\"}",
          "category_sn": "0004001",
          "child": []
        }
      ]
    }
  ],
  "desc": "success"
}
```

**Structure:**
- Hierarchical categories (parent → child)
- `child` array can be empty or contain sub-categories
- Category names are JSON strings with multi-language support

---

#### getProductByStore
**Endpoint:** `POST api/mobile/getProductByStore`

**Request:**
```json
{
  "store_id": 12
}
```

**Response:** See `/docs/menu/getProductByStore.json`

```json
{
  "result_code": 200,
  "products": [
    {
      "status": 1,
      "cid": 84,
      "cate_id": 99,
      "product_pic": "https://oss.jeffy.sg/...",
      "product_id": 589,
      "product_name": "{\"cn\":\"CR1 Chicken Rendang\",\"en\":\"CR1 Chicken Rendang\"}",
      "note": "Product description",
      "product_sn": "2080",
      "is_take_out": 1,
      "price": "6.80",
      "sort_sn": 1,
      "start_time": "07:00:00",
      "end_time": "22:00:00",
      "ingredient_name": "{\"cn\":\"other\",\"en\":\"other\"}",
      "ingredients_id": 3,
      "effective_start_time": 1615132800,
      "effective_end_time": 4102329600,
      "hasModifiers": 1
    }
  ],
  "desc": "success"
}
```

**Key Fields:**
- `hasModifiers`: 0 or 1 (determines if product has modifiers)
- `cate_id`: Links to category `id` from getMenu
- `price`: String format
- `is_take_out`: 1 = available for takeout, 0 = dine-in only
- Times are used for availability validation

---

#### getProductAtt
**Endpoint:** `POST api/mobile/getProductAtt`

**Request:**
```json
{
  "store_id": 12
}
```

**Response:** See `/docs/menu/getProductAtt.json` (large file ~6MB)

```json
{
  "result_code": 200,
  "atts": [
    {
      "product_id": 1,
      "product_type": 1,
      "atts": [
        {
          "att_id": 1,
          "attr_sn": "001",
          "att_name": "{\"en\":\"Drink Modifier\",\"cn\":\"Drink Modifier\"}",
          "multi_select": 1,
          "min_num": 0,
          "max_num": 1,
          "sort": 1,
          "att_val_info": [
            {
              "att_val_name": "{\"cn\":\"Kosong\",\"en\":\"Kosong\"}",
              "att_val_id": 2,
              "price": "0.00",
              "default_choose": 0,
              "att_val_sn": "2058",
              "min_num": 0,
              "max_num": 1,
              "sort": 1
            }
          ]
        }
      ]
    }
  ],
  "desc": "success"
}
```

**Structure:**
- Grouped by `product_id`
- Each product has array of attribute groups (`atts`)
- Each attribute group has:
  - `multi_select`: 1 = can select multiple, 0 = single select only
  - `min_num`, `max_num`: Selection constraints
  - `att_val_info`: Array of possible values
- Each value can have a `price` (additional cost)

---

#### getActivityComboWithPrice
**Endpoint:** `POST api/mobile/getActivityComboWithPrice`

**Request:**
```json
{
  "store_id": 12
}
```

**Response:** See `/docs/menu/getActivityComboWithPrice.json`

**Purpose:** Get combo/activity pricing and discounts

---

#### getStoreComboProduct
**Endpoint:** `POST api/mobile/getStoreComboProduct`

**Request:**
```json
{
  "store_id": 12
}
```

**Response:** See `/docs/menu/getStoreComboProduct.json`

**Purpose:** Get products available in combo deals

---

### 3. Authentication APIs

#### userLogin
**Endpoint:** `POST api/user/userLogin`

**Request:**
```json
{
  "storeId": 12,
  "countryCode": "65",
  "mobile": "12345678",
  "password": "123456"
}
```

**Response:**
```json
{
  "result_code": "200",
  "CRM": {
    "phoneNumber": "12345678",
    "countryCallingCode": "65",
    "isMember": true,
    "pdpa": 1,
    "name": "John Doe"
  },
  "desc": "Login successful"
}
```

**Error Codes:**
- `result_code: "500"` - Invalid credentials
- `result_code: "7103"` - User needs OTP verification

**Store Response:**
- Save to `localStorage` as `USER_INFO`
- Use for subsequent authenticated requests

---

#### getOTP
**Endpoint:** `POST api/user/getOTP`

**Request:**
```json
{
  "storeId": 12,
  "countryCode": "65",
  "mobile": "12345678",
  "functionName": "UserRegister"
}
```

**Function Names:**
- `"UserRegister"` - For new user registration
- `"ForgotPassword"` - For password reset

**Response:**
```json
{
  "result_code": "200",
  "desc": "OTP sent successfully"
}
```

---

#### activateAdvocadoUser
**Endpoint:** `POST api/user/advocadoActivateUser`

**Request:**
```json
{
  "storeId": 12,
  "countryCode": "65",
  "mobile": "12345678",
  "otp": "123456",
  "password": "newpin123",
  "name": "John Doe",
  "email": "john@example.com",
  "pdpa": 1
}
```

**Purpose:** Complete new user registration after OTP verification

---

#### getPDPAContent
**Endpoint:** `POST api/user/advocadoGetPDPA`

**Request:**
```json
{
  "storeId": 12
}
```

**Response:**
```json
{
  "result_code": "200",
  "advocadoPDPA": "PDPA agreement text..."
}
```

---

### 4. User Profile APIs

#### getCustomerInfo
**Endpoint:** `POST api/user/getCustomerInfo`

**Request:**
```json
{
  "storeId": 12,
  "countryCode": "65",
  "mobile": "12345678"
}
```

**Response:**
```json
{
  "result_code": "200",
  "CRM": {
    "phoneNumber": "12345678",
    "countryCallingCode": "65",
    "name": "John Doe",
    "email": "john@example.com",
    "balance": "50.00",
    "points": 150
  }
}
```

**Purpose:** Get latest user info including loyalty balances

---

### 5. Order APIs

#### mobileOrderRequest (sendMobileOrder)
**Endpoint:** `POST api/mobile/sendMobileOrder`

**Request:** Complex order object

```json
{
  "request": {
    "transaction": {
      "singleitems": {
        "singleitem": [
          {
            "mainproduct": "2080",
            "quantity": 2,
            "costEach": "6.80",
            "subproducts": {
              "subproduct": [
                {
                  "subproduct": "2058",
                  "quantity": 1,
                  "price": "0.00"
                }
              ]
            }
          }
        ]
      },
      "comboitems": {
        "comboitem": []
      },
      "payments": {
        "payment": [
          {
            "id": 60,
            "tender": "13.60"
          }
        ]
      },
      "returnurl": "https://mobileorder.jeffy.sg/paymentToStoreResponse",
      "cancelurl": "https://mobileorder.jeffy.sg/paymentcancel",
      "timeouturl": "https://mobileorder.jeffy.sg/timeout",
      "label": "John Doe",
      "saletypenum": 2,
      "storeid": 12
    }
  }
}
```

**Response:**
```json
{
  "result_code": "200",
  "sessionID": "SESSION123456789",
  "cloudOrderNumber": "ORD20250115001",
  "desc": "Order created successfully"
}
```

**Key Fields:**
- `sessionID`: Used for payment gateway
- `cloudOrderNumber`: Order reference number
- Save `cloudOrderNumber` to localStorage for later reference

---

#### paymentUpdate
**Endpoint:** `POST api/mobile/paymentUpdate`

**Request:**
```json
{
  "cloudOrderNumber": "ORD20250115001",
  "resultIndicator": "ABC123DEF456",
  "storeId": 12
}
```

**Purpose:** Called after payment gateway redirect to finalize order

---

### 6. Loyalty/Top-Up APIs

#### advocadoTopUpCredit
**Endpoint:** `POST api/mobile/advocadoTopUp`

**Request:**
```json
{
  "topUp": {
    "payment": {
      "paymentId": 60,
      "topUpAmount": "50.00",
      "campaignType": "stored-value"
    },
    "returnUrl": "https://mobileorder.jeffy.sg/home?type=stored-value",
    "cancelurl": "https://mobileorder.jeffy.sg/home",
    "timeouturl": "https://mobileorder.jeffy.sg/home",
    "salesType": 13,
    "storeId": 12,
    "mobile": "12345678",
    "countryCode": "65"
  }
}
```

**Response:**
```json
{
  "result_code": "200",
  "sessionID": "SESSION123",
  "cloudOrderNumber": "TOP20250115001"
}
```

---

#### verifyRedemptionPIN
**Endpoint:** `POST api/user/advocadoVerifyPIN`

**Request:**
```json
{
  "countryCode": "65",
  "mobile": "12345678",
  "pin": "1234",
  "storeId": 12
}
```

**Purpose:** Verify 4-digit redemption PIN for loyalty payments

---

### 7. Static Content APIs

#### getTNC
**Endpoint:** `POST api/mobile/getTNC`

**Request:**
```json
{
  "storeId": 12
}
```

---

#### getPrivacyPolicy
**Endpoint:** `POST api/mobile/getPrivacyPolicy`

**Request:**
```json
{
  "storeId": 12
}
```

---

#### getCancelRefunds
**Endpoint:** `POST api/mobile/getCancelRefunds`

**Request:**
```json
{
  "storeId": 12
}
```

---

#### getFeedback
**Endpoint:** `POST api/mobile/getFeedback`

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "message": "Feedback message",
  "storeId": 12
}
```

---

### 8. Order History API

#### GetOrderedItems (GET - Table Service)
**Endpoint:** `GET https://mobile.jeffy.sg/api/table/GetOrderedItems/{storeId}/{sessionId}`

**Purpose:** Get order history for table service session

**Request:** No body

**Response:**
```json
{
  "orders": [...]
}
```

---

## Response Codes

All APIs return a `result_code` field:

- `"200"` - Success
- `"500"` - General error (check `desc` for message)
- `"7103"` - Specific condition (e.g., user needs OTP)

**Standard Response Structure:**
```json
{
  "result_code": "200",
  "desc": "Description message",
  ... // Additional data
}
```

---

## Error Handling

From `APIService.js`:

```javascript
if (data.result_code != "200" && data.result_code != "7103") {
  data.isError = true;
}
```

**In Flutter:**
- Check `result_code == "200"` for success
- Handle `"7103"` as special case (redirect to OTP)
- All other codes are errors

---

## Multi-Language Support

Many fields use JSON string format for multiple languages:

```json
{
  "cat_name": "{\"cn\":\"Chinese Name\",\"en\":\"English Name\"}"
}
```

**To Parse:**
```dart
final nameJson = jsonDecode(category['cat_name']);
final englishName = nameJson['en'];
final chineseName = nameJson['cn'];
```

---

## Important Implementation Notes

### 1. iOS Chrome Compatibility
From React app: Always pre-filter product references before matching to avoid sparse arrays and undefined errors.

### 2. Request Flow on App Start
```
1. User accesses /locate/{storeId} or /locate/{storeId}/{sessionId}
2. Call locateStoreById (GET, no auth)
3. Store credentials in localStorage
4. Call getMenu, getProductByStore, getProductAtt in parallel
5. Store data locally
6. Navigate to auth or home
```

### 3. Order Submission Flow
```
1. Build order object with all items and modifiers
2. Call mobileOrderRequest
3. Receive sessionID and cloudOrderNumber
4. Configure payment gateway with sessionID
5. Show payment page
6. User completes payment
7. Gateway redirects with resultIndicator
8. Call paymentUpdate with cloudOrderNumber and resultIndicator
9. Show success/failure screen
```

### 4. State Persistence
Store in localStorage:
- `STORE_CREDENTIALS` - All store config
- `STORE_ID` - Store ID
- `USER_INFO` - User profile
- `BASKET` - Shopping cart
- `HAS_TABLE_SERVICE` - Boolean flag
- `SESSION_ID` - Table session ID (if applicable)

---

## Test Store GUID

From the example URLs provided:
- **Store ID:** `81898903-e31a-442a-9207-120e4a8f2a09`
- **Session ID (Table Service):** `b037d09b-7acb-446b-b6e8-f98307a614e7`

**Test URLs:**
- Quick Service: `https://orderuat.jeffy.sg/locate/81898903-e31a-442a-9207-120e4a8f2a09`
- Table Service: `https://orderuat.jeffy.sg/locate/81898903-e31a-442a-9207-120e4a8f2a09/b037d09b-7acb-446b-b6e8-f98307a614e7`

---

## Payment Gateway Integration

### Mastercard Payment Gateway

**Script URL:** Load in `web/index.html`
```html
<script src="{payment-gateway-url}/checkout.js"></script>
```

**JavaScript Interop:**
```dart
@JS('Checkout.configure')
external void configureCheckout(dynamic config);

@JS('Checkout.showPaymentPage')
external void showPaymentPage();
```

**Configuration:**
```javascript
window.Checkout.configure({
  session: {
    id: sessionID  // From mobileOrderRequest response
  },
  interaction: {
    merchant: {
      name: "Order",
      address: {
        line1: "200 sample st"
      }
    },
    displayControl: {
      billingAddress: "HIDE"
    }
  }
});
```

---

## Next Steps for Implementation

1. **Phase 4:** Implement API client with MD5 signing
2. **Phase 5:** Create models for all response structures
3. **Phase 6-8:** Implement each API call incrementally
4. **Phase 14:** Integrate payment gateway with JS interop

Refer to `IMPLEMENTATION_PLAN.md` for detailed phase-by-phase approach.
