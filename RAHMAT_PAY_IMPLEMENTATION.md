# Rahmat Pay Card Payment Implementation

## Overview
This document describes the implementation of Rahmat Pay card payment integration with automatic payment status checking.

## Flow

### 1. Payment Initiation (checkout.dart)
When the user selects card payment and clicks "Place Order":

1. **Create Invoice**: Call `RahmatPayService.createInvoice()` to create a payment invoice
   - Returns `short_link` (payment URL) and `invoice_id`
   - Example: `http://64.23.216.120:3000/rahmat-pay/status/INV-1764251352845-UF74Ea`

2. **Save Pending Payment**: Store payment details in SharedPreferences for later verification

3. **Show Status Dialog**: Display `_PaymentStatusDialog` that will poll for payment status

4. **Launch Payment URL**: Open the payment page in external browser

### 2. Payment Status Polling (rahmat_pay_transaction_service.dart)
The status dialog automatically checks payment status:

- **Polling Interval**: Every 3 seconds
- **Maximum Duration**: 5 minutes (100 checks)
- **Status Endpoint**: `GET http://64.23.216.120:3000/rahmat-pay/status/{invoiceId}`

### 3. Payment Status Handling

#### Success (status: "success", "paid", or "completed")
1. Clear pending payment from SharedPreferences
2. Clear the shopping cart
3. Close status dialog
4. Show success dialog
5. Navigate to home page (`/homeNew`)

#### Failure (status: "failed", "cancelled", or "error")
1. Clear pending payment
2. Close status dialog
3. Show error dialog
4. User stays on checkout page to retry

#### Timeout (5 minutes elapsed)
1. Close status dialog
2. Show timeout dialog informing user to check order history
3. User can manually verify payment status

## Files Modified/Created

### New Files
- **`lib/services/rahmat_pay_transaction_service.dart`**: Service to handle payment status polling and dialog management

### Modified Files
- **`lib/services/rahmat_pay_service.dart`**: Added `checkPaymentStatus()` method
- **`lib/pages/checkout.dart`**: Updated `_handleCardPayment()` to use transaction service

## API Endpoints Used

### 1. Create Invoice
```
POST http://64.23.216.120:3000/rahmat-pay/create-invoice
```
**Request Body:**
```json
{
  "branch_id": 1,
  "employee_id": 1,
  "order_type_id": 2,
  "payment_type_id": 3,
  "customer_quantity": 1,
  "pager_number": "12",
  "note": "Order comment",
  "amount": 50000,
  "lang": "ru",
  "ofd": [...]
}
```

**Response:**
```json
{
  "short_link": "http://64.23.216.120:3000/rahmat-pay/status/INV-...",
  "invoice_id": "INV-1764251352845-UF74Ea"
}
```

### 2. Check Payment Status
```
GET http://64.23.216.120:3000/rahmat-pay/status/{invoiceId}
```

**Response:**
```json
{
  "status": "success",
  "data": {
    // Additional payment details
  }
}
```

**Possible Status Values:**
- `"success"`, `"paid"`, `"completed"` - Payment successful
- `"pending"`, `"processing"` - Payment in progress
- `"failed"`, `"cancelled"`, `"error"` - Payment failed

## User Experience

1. User fills out checkout form and selects "Card" payment
2. User clicks "Place Order"
3. Status dialog appears: "Processing Payment - Waiting for payment..."
4. Browser opens with Rahmat Pay payment page
5. User completes payment in browser
6. User returns to app (manually or via deep link)
7. Status dialog automatically detects payment success
8. Success dialog appears
9. Cart is cleared
10. User is redirected to home page

## Error Handling

### Network Errors
- If status check fails, continue polling (don't fail immediately)
- Show current check count to user

### Payment Failures
- Show clear error message with status
- Allow user to retry payment

### Timeout
- After 5 minutes, show timeout dialog
- Inform user to check order history or contact support

## Testing

### Test Successful Payment
1. Go to checkout
2. Select card payment
3. Complete payment in browser
4. Return to app
5. Verify: Cart cleared, redirected to home, success message shown

### Test Failed Payment
1. Go to checkout
2. Select card payment
3. Cancel payment in browser
4. Return to app
5. Verify: Error message shown, cart not cleared, stay on checkout

### Test Timeout
1. Go to checkout
2. Select card payment
3. Don't complete payment
4. Wait 5 minutes
5. Verify: Timeout message shown

## Future Improvements

1. **Deep Linking**: Implement deep link to return user to app after payment
2. **Push Notifications**: Notify user when payment is confirmed
3. **Order History**: Add screen to view past orders and payment status
4. **Retry Logic**: Add exponential backoff for status checks
5. **Analytics**: Track payment success/failure rates
