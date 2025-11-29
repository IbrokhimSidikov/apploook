# Payment Status Dialog Design

## Overview
Redesigned payment status dialogs with modern, user-friendly UI for all three payment states: **Pending**, **Success**, and **Cancelled/Failed**.

---

## 🔄 Pending Status Dialog

### Design Features
- **Circular progress indicator** with brand yellow color (#FEC700)
- **Gradient background** (white to light grey)
- **Numbered step instructions** for user guidance
- **Progress bar** showing check count (e.g., 15/100)
- **Rounded corners** (20px border radius)
- **Elevated shadow** for depth

### Visual Elements
1. **Top Icon**: Animated circular progress indicator in yellow circle
2. **Title**: "Processing Payment" in bold, large font
3. **Status Badge**: Blue info box with "Waiting for payment confirmation..."
4. **Instructions Box**: Grey container with 2 numbered steps:
   - Step 1: Complete payment in browser
   - Step 2: Return to app after payment
5. **Progress Indicator**: Linear progress bar with yellow accent
6. **Cancel Button**: Outlined button at bottom

### Colors
- Primary: `#FEC700` (Brand Yellow)
- Background: White to Grey[50] gradient
- Status Badge: Blue[50] background, Blue[900] text
- Instructions: Grey[100] background

---

## ✅ Success Status Dialog

### Design Features
- **Large check circle icon** with green color and glow effect
- **Gradient background** (green[50] to white)
- **Shopping bag icon** in message box
- **Full-width action button**
- **Box shadow** on icon for emphasis

### Visual Elements
1. **Top Icon**: 100px green check circle with shadow glow
2. **Title**: "Payment Successful!" in green[700]
3. **Message Box**: White container with green border containing:
   - Shopping bag icon
   - Success message
   - Order confirmation text
4. **Action Button**: Full-width green button "Continue Shopping"

### Colors
- Primary: Green[600]
- Background: Green[50] to White gradient
- Icon Glow: Green with 30% opacity
- Border: Green[200]

---

## ❌ Cancelled/Failed Status Dialog

### Design Features
- **Cancel/Error icon** with red color and glow effect
- **Gradient background** (red[50] to white)
- **Dynamic title** (changes based on status)
- **Status badge** showing exact error
- **Helpful retry message**

### Visual Elements
1. **Top Icon**: 100px red cancel icon with shadow glow
2. **Title**: "Payment Cancelled" or "Payment Failed" (dynamic)
3. **Message Box**: White container with red border containing:
   - Error/Info icon (changes based on status)
   - Status-specific message
   - Status badge (e.g., "Status: cancelled")
   - Retry instructions
4. **Action Button**: Full-width red button "Try Again"

### Colors
- Primary: Red[600]
- Background: Red[50] to White gradient
- Icon Glow: Red with 30% opacity
- Status Badge: Red[50] background, Red[800] text
- Border: Red[200]

---

## ⏱️ Timeout Status Dialog

### Design Features
- **Clock icon** with orange color and glow effect
- **Gradient background** (orange[50] to white)
- **Informative message** with helpful tips
- **Icon bullets** for key information

### Visual Elements
1. **Top Icon**: 100px orange clock icon with shadow glow
2. **Title**: "Payment Status Unknown" in orange[800]
3. **Message Box**: White container with orange border containing:
   - Help icon
   - Main message
   - Divider line
   - Two bullet points with icons:
     - ✓ If completed, order will be processed
     - 👤 Contact support if needed
4. **Action Button**: Full-width orange button "I Understand"

### Colors
- Primary: Orange[600]
- Background: Orange[50] to White gradient
- Icon Glow: Orange with 30% opacity
- Border: Orange[200]
- Bullet Icons: Green[600] and Blue[600]

---

## Common Design Patterns

### Typography
- **Title**: 24px, Bold
- **Body Text**: 16px, Regular
- **Small Text**: 13-14px
- **Badge Text**: 12px, Semi-bold

### Spacing
- **Container Padding**: 32px
- **Element Spacing**: 12-24px
- **Icon Size**: 60px (in 100px container)
- **Button Height**: 48px (16px vertical padding)

### Border Radius
- **Dialog**: 20px
- **Containers**: 12px
- **Buttons**: 30px (pill shape)
- **Badges**: 8px

### Shadows
- **Dialog Elevation**: 8
- **Icon Glow**: 20px blur, 5px spread, 30% opacity

---

## User Experience Improvements

### Before (Old Design)
- ❌ Basic AlertDialog with minimal styling
- ❌ Text-heavy with no visual hierarchy
- ❌ Generic icons
- ❌ No progress indication
- ❌ Unclear next steps

### After (New Design)
- ✅ Modern Dialog with gradients and shadows
- ✅ Clear visual hierarchy with icons and badges
- ✅ Large, colorful status icons with glow effects
- ✅ Progress bar showing real-time status
- ✅ Step-by-step instructions
- ✅ Status-specific colors (yellow/green/red/orange)
- ✅ Full-width action buttons
- ✅ Consistent design language

---

## Implementation Notes

### Status Detection
The dialog automatically detects three main statuses from the API:
- **Pending**: `"pending"`, `"processing"` → Shows pending dialog
- **Success**: `"success"`, `"paid"`, `"completed"` → Shows success dialog
- **Failed**: `"failed"`, `"cancelled"`, `"error"` → Shows failure dialog

### Responsive Design
- All dialogs use `mainAxisSize: MainAxisSize.min` for content-based sizing
- Full-width buttons for better mobile UX
- Flexible text containers that adapt to content length

### Accessibility
- High contrast colors for readability
- Large touch targets (48px minimum)
- Clear visual feedback for all states
- Descriptive text for screen readers
