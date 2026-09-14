# InvoicePro – Billing Manager

Production-ready invoice and billing management app for Android, iOS, macOS, web, and Windows (Final Year Project).

## Run

```bash
flutter pub get
flutter run                 # current device
flutter run -d android
flutter run -d chrome
flutter run -d windows
```

iOS and macOS builds need Xcode on a Mac:

```bash
flutter run -d ios
flutter run -d macos
```

Production flavor (after a second Firebase project is linked):

```bash
flutter run --dart-define=FIREBASE_ENV=production
```

## Test

```bash
flutter analyze
flutter test
```

## Phase 2 — Firebase Auth setup

The app is linked to Firebase project **invoice-app-c8170**:

- Android: `com.invoicepro.invoice_pro`
- iOS / macOS: `com.invoicepro.invoicePro`
- Web / Windows: InvoicePro Web client options

Email/Password sign-in is enabled. `lib/firebase_options.dart` has `developmentConfigured = true`.

Register and sign in with a real email after deploying rules:

```bash
npx -y firebase-tools@latest deploy --only auth,firestore:rules,firestore:indexes,storage --project invoice-app-c8170
flutter run
```

Do not put Firebase Admin keys, service-account JSON, or passwords in the repo.

## Phase 3 — Business profile and dashboard

After Phase 2 is connected, deploy Storage rules as well:

```bash
firebase deploy --only firestore:rules,storage --project <YOUR_DEV_PROJECT_ID>
```

- Register creates `users/{uid}` **and** `businesses/{businessId}` (owner-only).
- Profile → **Business profile** edits name, owner, logo, contact, address, tax, currency (default PKR), invoice prefix, payment instructions, and terms. Logo is gallery-only via Firebase Storage (`businesses/{id}/logo.jpg`, max 2 MB).
- Dashboard totals, charts, recent lists, and top customers/products are calculated from Firestore invoices, payments, expenses, customers, and products. Empty collections show zeros and empty states — nothing is mocked.
- Subcollection writes stay closed until later phases, except **customers** in Phase 4.

## Phase 4 — Customers

Customers live at `businesses/{businessId}/customers/{customerId}`. Redeploy Firestore rules after this phase:

```bash
firebase deploy --only firestore:rules --project <YOUR_DEV_PROJECT_ID>
```

- Add / edit / delete: name, company, email, phone, address, city, notes
- Search and filters (all, outstanding, has email)
- Customer details with invoice/payment history, total purchases, and outstanding — all from Firestore. Empty until invoices exist.

## Phase 5 — Products and services

Catalogue items live at `businesses/{businessId}/products/{productId}` with categories at `.../categories/{categoryId}`. Redeploy Firestore and Storage rules:

```bash
firebase deploy --only firestore:rules,storage --project <YOUR_DEV_PROJECT_ID>
```

- Add / edit / delete products and services: name, SKU, description, category, price, cost, tax, stock, unit, gallery photo
- Search and filters (all, products, services, low stock, category)
- Stock is tracked for products; services do not use stock
- Prices and cost are integer minor units (paisa). Photos go to `businesses/{id}/products/{productId}.jpg` (max 2 MB)

## Phase 6 — Invoices

Invoices live at `businesses/{businessId}/invoices/{invoiceId}`. Numbers are assigned from the business prefix and `invoiceNextNumber` in a Firestore transaction so two devices cannot take the same number. Redeploy Firestore rules:

```bash
firebase deploy --only firestore:rules --project <YOUR_DEV_PROJECT_ID>
```

- Create / edit / delete (drafts and cancelled) / duplicate / cancel / mark sent
- Existing or new customer, invoice date, due date, payment terms
- Line items from products/services or a custom line: quantity, unit price, discount, tax, line total
- Subtotal, discount, tax, and grand total use integer minor units
- Status: draft, sent, unpaid, partially paid, paid, overdue (from due date), cancelled
- Search and filters (all, draft, unpaid, overdue, paid, cancelled)

## Phase 7 — Invoice PDF

Professional A4 PDFs are generated on the device from the saved invoice (integer money, business/customer snapshots). Redeploy Storage rules if you have not since Phase 5:

```bash
firebase deploy --only storage --project <YOUR_DEV_PROJECT_ID>
```

- Preview, generate, share, print, and save from invoice details
- PDF includes logo (when uploaded), business and customer details, dates, line items, totals, payment status, notes, and terms
- Generate also uploads `businesses/{id}/invoices/{invoiceId}.pdf` (owner-only, max 8 MB)
- Save writes a copy under the app documents folder on the device

## Phase 8 — Payments

Payments live at `businesses/{businessId}/payments/{paymentId}`. Recording a payment updates the invoice `paidMinor` and status in a Firestore transaction. Redeploy Firestore rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes --project <YOUR_DEV_PROJECT_ID>
```

- Record a payment or mark an invoice paid from invoice details
- Methods: Cash, Bank Transfer, Credit/Debit Card, JazzCash, Easypaisa, Other
- Partial payments set status to partially paid; paying the remaining balance marks the invoice paid
- Outstanding = total − paid (integer minor units)
- Payment history on the invoice, customer, and dashboard
- Remove a payment to recalculate the invoice balance

## Phase 9 — Expenses

Expenses live at `businesses/{businessId}/expenses/{expenseId}`. Amounts are integer minor units (paisa). Redeploy Firestore rules after this phase:

```bash
firebase deploy --only firestore:rules --project <YOUR_DEV_PROJECT_ID>
```

- Add / edit / delete: title, category, amount, date, description
- Categories: Rent, Salary, Electricity, Transport, Marketing, Inventory, Other
- Search and category filters
- Open from Profile → **Expenses**, or tap the dashboard Expenses total
- Dashboard net profit = revenue − expenses for the selected date range

## Phase 10 — Reports

Reports are calculated from live invoices, payments, and expenses for the selected dates. Nothing is stored as fake report documents. Open from Profile → **Reports**, or the dashboard insights icon.

- Sales: daily / weekly / monthly / yearly (Today, This week, This month, This year, or a custom range)
- Invoice: paid, unpaid, overdue, cancelled
- Customer: billed and outstanding
- Product: quantity sold and line totals
- Expense: totals by category
- Charts and tables on each report
- Preview, share, print, and save as PDF

## Phase 11 — Notifications and FCM

Inbox items live at `businesses/{businessId}/notifications/{notificationId}`. The FCM token is stored on `users/{uid}` (`fcmToken`, `fcmTokenUpdatedAt`). Redeploy Firestore rules after this phase, and enable **Cloud Messaging** in the Firebase console:

```bash
firebase deploy --only firestore:rules --project <YOUR_DEV_PROJECT_ID>
```

- Events: invoice created (when it leaves draft), payment received, invoice overdue
- Drafts, duplicates, ordinary edits, cancel, mark sent, expenses, and reports do **not** create notifications
- In-app inbox: Profile → **Notifications**, or the dashboard bell (unread badge)
- Tap a notification to open the related invoice
- Overdue alerts also show a local OS notification when Firebase is connected. Many newly overdue invoices in one scan share one banner
- Issuing an invoice or recording a payment only writes the inbox (the person who did it already sees a snackbar)
- Foreground FCM messages show as local notifications. Tapping one opens the invoice when `invoiceId` is in the payload
- Push while the app is killed needs Cloud Functions (or a similar server) to send FCM. That is **not** in this phase

## Phase 13 — Testing and performance

- List watches (invoices, customers, products, payments, expenses) load in pages of `AppConstants.listPageSize` (40). **Load more** grows the Firestore window.
- Notification inbox is capped at `notificationInboxLimit` (100).
- Dashboard queries use `dashboardQueryLimit` (200) and no longer recreate the dashboard provider on every list length change (debounced refresh instead).
- Gallery image picks use shared max dimension / quality constants before upload.
- Invoices store denormalized `lineProductIds` so product-in-use checks can use `array-contains` instead of scanning every invoice.
- Expanded unit/widget coverage: auth flows, provider CRUD, pagination, cross-business isolation, phone/tablet layout, light/dark empty states.

Redeploy indexes if you changed them:

```bash
firebase deploy --only firestore:indexes --project <YOUR_DEV_PROJECT_ID>
```

## Phase 12 — App Check and Crashlytics

Firestore and Storage rules stay owner-only (`allow read, write: if true` is never used). Redeploy Storage rules if you have not since this phase (image uploads now allow jpeg/png/webp only):

```bash
firebase deploy --only firestore:rules,storage --project <YOUR_DEV_PROJECT_ID>
```

### App Check

1. Firebase console → **App Check** → register the Android app with **Play Integrity**.
2. Add the app's SHA-256 signing cert (debug and later the release key) in Project settings.
3. Debug / emulator: run the app, copy the App Check **debug token** from logcat (printed by the debug provider, not by InvoicePro), then **Manage debug tokens** and add it.
4. Start in **Monitor** mode. Switch to **Enforce** only after a genuine device and your debug token both succeed.
5. Optional CI: `--dart-define=APP_CHECK_DEBUG_TOKEN=<token>` — do not commit or log that token.

Release builds use Play Integrity. Debug builds use the debug provider. Widget tests never start Firebase, so they never talk to App Check.

### Crashlytics

Enable **Crashlytics** in the Firebase console. Flutter errors, isolate errors, and `AppLogger.error` (from repositories and providers) are recorded after Firebase starts. Emails, passwords, and long tokens are stripped. Crashlytics user id is the Auth uid, never the email.

## Architecture

```
lib/
  core/           # theme, constants, utils, reusable widgets
  models/         # shared domain types
  providers/      # app-level ChangeNotifiers
  repositories/   # Firebase Auth, users, business, dashboard, customers, products, invoices, payments, expenses, notifications
  services/       # bootstrap helpers, local storage, Storage uploads, invoice PDF, report PDF, FCM, App Check, Crashlytics
  screens/        # UI
  routes/         # go_router
  firebase_options.dart
  app.dart
  main.dart
```

## App identity

| Item | Value |
| --- | --- |
| Display name | Invoice App (change `AppConstants.appName` and native labels) |
| Android applicationId | `com.invoicepro.invoice_pro` |
| iOS / macOS bundle id | `com.invoicepro.invoicePro` |
| Version | `1.0.0+1` in `pubspec.yaml` |
| Default currency | PKR | 

Signing keystores and `key.properties` are gitignored. Release signing is configured in a later phase — do not commit credentials.
