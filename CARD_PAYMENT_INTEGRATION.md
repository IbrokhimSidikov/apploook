# Card Payment Integration with Rahmat Pay

## Overview
This document describes the card payment integration using Rahmat Pay API that has been implemented in the checkout flow.

## Changes Made

### 1. New Service: `rahmat_pay_service.dart`
**Location:** `/lib/services/rahmat_pay_service.dart`

**Key Features:**
- Creates invoices with Rahmat Pay API
- Converts cart items to OFD (fiscal data) format
- Launches payment URL in external browser
- Manages pending payment state
- Determines order type IDs based on order selection

**Main Methods:**
- `createInvoice()` - Creates payment invoice and returns short_link
- `launchPaymentUrl()` - Opens payment page in browser
- `convertCartItemsToOFD()` - Formats cart items for fiscal data
- `savePendingCardPayment()` - Saves payment state for verification
- `getOrderTypeId()` - Maps order type index to API order type ID

### 2. Updated: `checkout.dart`
**Location:** `/lib/pages/checkout.dart`

**Changes:**
1. **Removed Cash Payment Option** - Cash is no longer available
2. **Added Card Payment Option** - Available for all order types (Delivery, Self-Pickup, Carhop, In-Restaurant)
3. **Added Card Payment Handler** - `_handleCardPayment()` method
4. **Integrated with Order Flow** - Card payment triggers before order submission

## Payment Flow

### Step-by-Step Process:

1. **User selects Card payment** in checkout
2. **User clicks "Proceed with Order"**
3. **System validates** order details (address/branch, payment method, etc.)
4. **Card payment handler executes:**
   - Gets branch configuration
   - Retrieves bearer token from Sieves API
   - Converts cart items to OFD format
   - Creates invoice via Rahmat Pay API
   - Receives `short_link` in response
5. **System launches payment URL** in external browser
6. **User completes payment** on Rahmat Pay checkout page
7. **User returns to app** and is navigated to home screen

## API Integration Details

### Endpoint
```
POST http://64.23.216.120:3000/rahmat-pay/create-invoice
```

### Headers
```
Content-Type: application/json
Authorization: Bearer {sieves_api_token}
```

### Request Body Structure
```json
{
  "branch_id": 6,
  "employee_id": 123,
  "order_type_id": 2,
  "payment_type_id": 3,
  "customer_quantity": 1,
  "pager_number": "998901234567",
  "note": "Order comment",
  "amount": 500000,
  "lang": "ru",
  "ofd": [
    {
      "qty": 1,
      "price": 225000000,
      "mxik": "06401004002000000",
      "total": 225000000,
      "package_code": "1506113",
      "name": "Product name"
    }
  ]
}
```

### Response Structure
```json
{
  "short_link": "https://dev-checkout.multicard.uz/invoice/0430afe3-cc4c-11f0-af7c-005056b4367d",
  "invoice_id": "0430afe3-cc4c-11f0-af7c-005056b4367d"
}
```

## Order Type Mapping

| Order Type Index | Order Type Name | API order_type_id |
|-----------------|-----------------|-------------------|
| 0 | Delivery | 2 |
| 1 | Self-Pickup | 1 |
| 2 | Carhop | 8 |
| 3 | In-Restaurant | 3 |

## Payment Type ID
- **Card Payment:** `payment_type_id = 3`

## Important Notes

### 1. OFD Items (Fiscal Data)
Currently using placeholder values for:
- `mxik` - Product classification code
- `package_code` - Package identifier

**TODO:** Add these fields to your product model for accurate fiscal reporting.

### 2. Bearer Token
The bearer token is retrieved from the branch configuration's `sievesApiToken` field.

### 3. Amount Format
- Amount is sent in UZS (Uzbek Som)
- No conversion to tiyin needed for the main amount
- OFD item prices are in tiyin (multiply by 100)

### 4. Language
Currently hardcoded to `"ru"` (Russian).
**TODO:** Get language from app locale settings.

### 5. Delivery Fee
For delivery orders (index 0), the total includes delivery fee:
```dart
total: orderPrice + deliveryFee
```

For other order types, only order price is used.

## Testing Checklist

- [ ] Test Delivery order with card payment
- [ ] Test Self-Pickup order with card payment
- [ ] Test Carhop order with card payment
- [ ] Test In-Restaurant order with card payment
- [ ] Verify invoice creation API call
- [ ] Verify payment URL launches correctly
- [ ] Test with different cart items
- [ ] Test with modifiers/add-ons
- [ ] Verify OFD data format
- [ ] Test error handling (network errors, API errors)
- [ ] Test pending payment state management

## Error Handling

The implementation includes error handling for:
- Missing branch selection
- Failed invoice creation
- Failed payment URL launch
- Network errors
- API errors

Errors are displayed to users via SnackBar notifications.

## Future Enhancements

1. **Payment Verification:** Add webhook or polling to verify payment completion
2. **MXIK Codes:** Add proper product classification codes to product model
3. **Package Codes:** Add package identifiers to product model
4. **Localization:** Use app locale for language parameter
5. **Payment Status Tracking:** Similar to Payme transaction tracking
6. **Receipt Generation:** Store and display payment receipts

## Dependencies

- `url_launcher: ^6.0.9` - Already included in pubspec.yaml
- `http` - For API calls
- `shared_preferences` - For storing pending payment state

## Files Modified

1. `/lib/services/rahmat_pay_service.dart` - **NEW**
2. `/lib/pages/checkout.dart` - **MODIFIED**
   - Added import for RahmatPayService
   - Removed Cash payment option
   - Added Card payment option
   - Added `_handleCardPayment()` method
   - Integrated card payment in order submission flow
