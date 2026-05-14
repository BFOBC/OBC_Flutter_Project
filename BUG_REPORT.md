# OBC Smart App — Bug Report
**Date:** 2026-05-14  
**Branch:** development  
**Analysis Type:** Static Code Analysis  
**Total Bugs Found:** 24

---

## Severity Legend
| Symbol | Severity | Meaning |
|--------|----------|---------|
| 🔴 | CRITICAL | App crash / data loss |
| 🟠 | HIGH | Feature broken / wrong behavior |
| 🟡 | MEDIUM | UX broken / silent failure |
| 🟢 | LOW | Code quality / minor issue |

---

## 🔴 CRITICAL BUGS (5)

---

### BUG-001 — Race Condition: `markMessagesAsRead` runs before `chatId` is set
**File:** `lib/ui/chat/ChatDetailScreen.dart` · Lines 37–47  
**Category:** Race Condition / Null Safety  

**Problem:**
```dart
@override
void initState() {
  super.initState();
  _getChatId();                   // ❌ async, NOT awaited
  markMessagesAsReadWithoutIndex(); // runs immediately with chatId = ''
}

Future<void> markMessagesAsReadWithoutIndex() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)   // chatId is still '' here!
```
`_getChatId()` is async and sets `chatId` via `setState()`, but `markMessagesAsReadWithoutIndex()` fires in the same frame before it completes. Firestore receives an empty document path.

**Impact:** Messages are never marked as read. Firestore query on empty path silently fails or throws.

**Fix:** Await `_getChatId()` before calling dependent methods, or call `markMessagesAsReadWithoutIndex()` inside `_getChatId()` after chatId is set.

---

### BUG-002 — Force Unwrap on `FirebaseAuth.currentUser` in `CourierMap`
**File:** `lib/ui/courier/CourierMap.dart` · Line 63  
**Category:** Null Safety / Crash  

**Problem:**
```dart
@override
void initState() {
  super.initState();
  _currentUser = FirebaseAuth.instance.currentUser!; // ❌ Force unwrap
  checkAndAnimateUserLocation(_currentUser.uid);
}
```
If Firebase auth state is temporarily null (token refresh, cold start), this crashes immediately with `Null check operator used on null value`.

**Impact:** App crashes every time `CourierMap` loads in an invalid auth state.

**Fix:** Replace with null-safe check:
```dart
_currentUser = FirebaseAuth.instance.currentUser;
if (_currentUser == null) { Navigator.pop(context); return; }
```

---

### BUG-003 — Invalid Google Maps Zoom Level (500.0)
**File:** `lib/ui/courier/CourierMap.dart` · Line 1145  
**Category:** Logic Error / Crash  

**Problem:**
```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: _baseLocation,
    zoom: 500.0,  // ❌ Invalid — max zoom is ~21
  ),
)
```
Google Maps maximum zoom is ~21. Passing `500.0` causes undefined behavior and may crash the map widget on certain devices.

**Impact:** Courier map may fail to render entirely.

**Fix:** Set zoom to a valid value, e.g., `zoom: 14.0`.

---

### BUG-004 — Force Unwrap on Nullable `getCountryCodeByLatLong()`
**File:** `lib/ui/courier/CourierMap.dart` · Lines 722–727  
**Category:** Null Safety / Crash  

**Problem:**
```dart
if (country.isEmpty) {
  final db = DatabaseOperation();
  country = (await db.getCountryCodeByLatLong(lat, long))!; // ❌ Force unwrap
}
```
If the SQLite lookup returns null (location not in database), the force unwrap crashes.

**Impact:** App crashes when updating base location for any airport not in the local database.

**Fix:** Use null-coalescing: `country = (await db.getCountryCodeByLatLong(lat, long)) ?? '';`

---

### BUG-005 — Unsafe Cast Before Existence Check in `BrokerProfileScreen`
**File:** `lib/ui/broker/BrokerProfileScreen.dart` · Line 59  
**Category:** Null Safety / Crash  

**Problem:**
```dart
Map<String, dynamic> data = profileSnapshot.data() as Map<String, dynamic>; // ❌ Cast first

if (profileSnapshot.exists) { // ← Existence check comes AFTER the cast
  _nameController.text = data['name'] ?? 'N/A';
```
If `profileSnapshot.data()` returns null, the cast throws a `TypeError` before the existence check can protect the code.

**Impact:** App crashes on profile load if Firestore document is empty.

**Fix:** Move existence check before the cast, or use `profileSnapshot.data()?.cast<String, dynamic>()`.

---

## 🟠 HIGH BUGS (6)

---

### BUG-006 — `BrokerMap` Force Unwrap on `countryCode`
**File:** `lib/ui/broker/BrokerMap.dart` · Line 165  
**Category:** Null Safety / Crash  

**Problem:**
```dart
final String countryCode = searchedLocation[0].countryCode!; // ❌ Force unwrap
```
`countryCode` from geocoding result may be null for international locations or edge cases.

**Impact:** App crashes when broker searches for airports that lack a `countryCode`.

**Fix:** `final String countryCode = searchedLocation[0].countryCode ?? '';`

---

### BUG-007 — Asset Loading Without Try-Catch in `BrokerMap`
**File:** `lib/ui/broker/BrokerMap.dart` · Lines 227–230  
**Category:** Missing Error Handling / Crash  

**Problem:**
```dart
BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
  ImageConfiguration(size: Size(24, 24)),
  'assets/place_holder_man.png',
); // ❌ No try-catch — crashes if asset missing
```
No error handling around asset loading. If the asset path changes or file is missing from build, the app crashes.

**Impact:** Broker map crashes on load if the asset is missing from the bundle.

**Fix:** Wrap in try-catch and fall back to `BitmapDescriptor.defaultMarker`.

---

### BUG-008 — `setState()` Called After Dispose in `CompleteMilestone`
**File:** `lib/ui/courier/missions/CompleteMilestone.dart` · Line 251  
**Category:** setState after dispose / Crash  

**Problem:**
```dart
await firestoreService.updateMilestoneStatus(
  milestone.milestoneNodeID.toString(),
  "Completed",
);

setState(() {                    // ❌ No mounted check
  milestonesFuture = _fetchMilestones();
});
```
If the user navigates away between the `await` and `setState()`, this throws: `setState() called after dispose()`.

**Impact:** App crashes if user closes the screen during a milestone update.

**Fix:** Add `if (mounted)` guard before `setState()`.

---

### BUG-009 — `CourierProfile` Loading Spinner Never Shows
**File:** `lib/ui/courier/CourierProfile.dart` · Lines 117–151  
**Category:** Logic Error / UI Bug  

**Problem:**
```dart
_isUploading = true;  // ❌ Direct assignment — no setState()

// ... long async operations ...

_isUploading = false; // ❌ Direct assignment in success block
_isUploading = false; // ❌ Direct assignment in catch block
```
State changes are direct assignments instead of `setState(() { ... })`. The build method checks `if (_isUploading)` to show a spinner, but it never triggers a rebuild.

Compare with `BrokerProfileScreen` which correctly uses `setState()` for the same pattern.

**Impact:** Loading spinner never appears/disappears during image upload — no user feedback.

**Fix:** Wrap all `_isUploading` changes in `setState()`.

---

### BUG-010 — `CourierProfile` Missing `mounted` Check After Async Operations
**File:** `lib/ui/courier/CourierProfile.dart` · Lines 117–152  
**Category:** setState after dispose / Crash  

**Problem:**
```dart
final pickedFile = await ImagePicker().pickImage(...); // Long async wait
// ... no mounted check ...
_isUploading = true;

await FirebaseFirestore.instance.collection('courier').doc(userId).set(...);
// ... no mounted check ...
_isUploading = false; // Could be called on disposed widget
```

**Impact:** "setState() called after dispose()" crash if user navigates away during image selection or upload.

**Fix:** Add `if (!mounted) return;` after each `await`.

---

### BUG-011 — `handleJobAction()` Fire-and-Forget Firebase Call in `JobDetails`
**File:** `lib/ui/courier/JobDetails.dart` · Lines 287–294  
**Category:** Missing Error Handling / Logic Error  

**Problem:**
```dart
service.updateJobStatus(nodeID, jobStatus); // ❌ Not awaited, no error handling

service.updateEmptyLegTableJobStatus(...)
  .then((_) { print('✅ success'); })
  .catchError((error) { print('❌ Failed: $error'); }); // Error caught but user not notified
```
First call is completely fire-and-forget. Second call catches errors only in print — no UI feedback to the user.

**Impact:** Job status updates can fail silently. User thinks action succeeded when it didn't.

**Fix:** `await` both calls inside a try-catch and show an error dialog on failure.

---

## 🟡 MEDIUM BUGS (10)

---

### BUG-012 — String Interpolation Bug in `ViewBrokerMissions`
**File:** `lib/ui/broker/mission/ViewBrokerMissions.dart` · Line 125  
**Category:** Logic Error / UI Bug  

**Problem:**
```dart
message: "Your Job is started by $courierData['name']",
// ❌ This produces: "Your Job is started by {name: John, ...}['name']"
```

**Fix:**
```dart
message: "Your Job is started by ${courierData?['name'] ?? 'Courier'}",
```

---

### BUG-013 — Dead Code After `return` in `ManageLegsAndMilestones`
**File:** `lib/ui/broker/mission/ManageLegsAndMilestones.dart` · Lines 100–107  
**Category:** Logic Error / Dead Code  

**Problem:**
```dart
onWillPop: () async {
  bool shouldLeave = await showExitConfirmationDialog(context);
  return shouldLeave;
  dispose();   // ❌ Unreachable — after return
  return true; // ❌ Dead code
},
```

**Impact:** `dispose()` is never explicitly called via this path. Code is misleading.

---

### BUG-014 — `OnlineStatusProvider` Hardcoded to `true`
**File:** `lib/ui/common/utils/OnlineStatusProvider.dart`  
**Category:** Logic Error / Feature Broken  

**Problem:**
```dart
bool _isOnline = true; // ❌ Always true, never synced with actual connectivity
```
The provider is used in `DrawerScreen` to indicate connectivity but always returns `true` regardless of actual network state. The `connectivity_plus` package is imported but not wired to this provider.

**Impact:** App always shows "Online" even when the user has no internet.

---

### BUG-015 — `ChatListScreen` Null Name Fallback Logic
**File:** `lib/ui/chat/ChatListScreen.dart` · Lines 58–70  
**Category:** Null Safety / Logic Error  

**Problem:**
```dart
'name': (data['name'] ?? '').toString().trim().isNotEmpty
    ? data['name']   // ❌ Returns raw (possibly null) value after null check
    : 'Unknown Courier',
```
The ternary checks if trimmed name is non-empty, then returns `data['name']` which could still be null.

**Fix:** Return `data['name'].toString().trim()` in the true branch.

---

### BUG-016 — Duplicate `WidgetsFlutterBinding.ensureInitialized()` in `main.dart`
**File:** `lib/main.dart` · Lines 24 and 36  
**Category:** Code Error / LOW  

**Problem:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Line 24
  // ... Firebase.initializeApp() ...
  WidgetsFlutterBinding.ensureInitialized(); // Line 36 — duplicate call
```

**Impact:** Redundant but harmless. Indicates missing code review. Remove the duplicate.

---

### BUG-017 — `DataSyncScreen` No Validation on Empty Credentials
**File:** `lib/ui/common/screens/DataSyncScreen.dart` · Lines 103–111  
**Category:** Missing Error Handling  

**Problem:**
```dart
await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,    // Could be '' from empty SharedPreferences
  password: password, // Could be '' from empty SharedPreferences
);
```
No validation that `email` and `password` are non-empty before calling Firebase Auth.

**Impact:** Firebase throws `invalid-email` error with no user-facing message.

---

### BUG-018 — `CourierProfile` Missing `mounted` on Firestore call
**File:** `lib/ui/courier/CourierProfile.dart` · Line 139  
**Category:** Missing Error Handling  

**Problem:**
```dart
await FirebaseFirestore.instance.collection('courier').doc(userId).set(
  {'profilePictureUrl': uploadedImageUrl},
  SetOptions(merge: true),
); // ❌ No try-catch
_isUploading = false;
showCustomToast("Profile updated successfully!"); // ❌ Shows success even if Firestore fails
```
Success toast is shown even if the Firestore write silently fails because there's no try-catch around it.

---

### BUG-019 — `PlaceNewJob` Constructor Parameters Unused
**File:** `lib/ui/broker/mission/PlaceNewJob.dart` · Line 13  
**Category:** Logic Error / Dead Code  

**Problem:**
```dart
PlaceNewJob({
  super.key,
  this.data,
  required this.onSave,
  required String brokerKey,   // ❌ Not stored in any field
  required String courierKey,  // ❌ Not stored in any field
});
```
Both `brokerKey` and `courierKey` are accepted but never stored or used in the widget.

**Impact:** Callers pass data that is silently ignored.

---

### BUG-020 — `EmptyLegMainScreen` Type Mismatch: `int` vs `double` for `rating`
**File:** `lib/ui/courier/emptyleg/EmptyLegMainScreen.dart` · Line 197, 227  
**Category:** Type Mismatch / Runtime Error  

**Problem:**
```dart
// Model declaration:
int rating; // Line 197

// Factory constructor:
rating: (map['rating'] ?? 0).toDouble(), // ❌ Assigns double to int field
```

**Impact:** Runtime type error when parsing flight data from Firestore.

---

### BUG-021 — `SearchCourier` Rating Calculation Before Data Loaded
**File:** `lib/ui/broker/SearchCourier.dart` · Lines 87–120  
**Category:** Async Race Condition / Logic Error  

**Problem:**
```dart
fetchCourierData(); // ❌ Async, not awaited
// Immediately after:
if (courierProfile?.ratings != null) { // courierProfile is still null here
```

**Impact:** Rating calculation runs with null `courierProfile` — result is always default/zero.

---

## 🟢 LOW BUGS (3)

---

### BUG-022 — Typo in Notification Setup: `notificationListner`
**File:** `lib/main.dart`  
**Category:** Code Quality  
**Problem:** Method named `notificationListner` (misspelled — should be `notificationListener`).

---

### BUG-023 — `ManageLegsAndMilestones` Unreachable `dispose()` Call
**File:** `lib/ui/broker/mission/ManageLegsAndMilestones.dart`  
**Category:** Dead Code  
**Problem:** `dispose()` called after a `return` statement — never executes.

---

### BUG-024 — Missing `const` on Static Widget Constructors
**File:** Multiple files  
**Category:** Performance  
**Problem:** Many static widgets (e.g., `SizedBox`, `Text`, `Icon`) are not marked `const`, causing unnecessary rebuilds.

---

## Summary Table

| Bug ID | File | Severity | Category |
|--------|------|----------|----------|
| BUG-001 | ChatDetailScreen.dart | 🔴 Critical | Race Condition |
| BUG-002 | CourierMap.dart | 🔴 Critical | Null Safety |
| BUG-003 | CourierMap.dart | 🔴 Critical | Invalid Value |
| BUG-004 | CourierMap.dart | 🔴 Critical | Null Safety |
| BUG-005 | BrokerProfileScreen.dart | 🔴 Critical | Null Safety |
| BUG-006 | BrokerMap.dart | 🟠 High | Null Safety |
| BUG-007 | BrokerMap.dart | 🟠 High | Missing Error Handling |
| BUG-008 | CompleteMilestone.dart | 🟠 High | setState after dispose |
| BUG-009 | CourierProfile.dart | 🟠 High | UI Bug / Logic Error |
| BUG-010 | CourierProfile.dart | 🟠 High | setState after dispose |
| BUG-011 | JobDetails.dart | 🟠 High | Missing Error Handling |
| BUG-012 | ViewBrokerMissions.dart | 🟡 Medium | String Interpolation |
| BUG-013 | ManageLegsAndMilestones.dart | 🟡 Medium | Dead Code |
| BUG-014 | OnlineStatusProvider.dart | 🟡 Medium | Feature Broken |
| BUG-015 | ChatListScreen.dart | 🟡 Medium | Null Safety |
| BUG-016 | main.dart | 🟡 Medium | Duplicate Call |
| BUG-017 | DataSyncScreen.dart | 🟡 Medium | Missing Validation |
| BUG-018 | CourierProfile.dart | 🟡 Medium | Missing Error Handling |
| BUG-019 | PlaceNewJob.dart | 🟡 Medium | Dead Code |
| BUG-020 | EmptyLegMainScreen.dart | 🟡 Medium | Type Mismatch |
| BUG-021 | SearchCourier.dart | 🟡 Medium | Race Condition |
| BUG-022 | main.dart | 🟢 Low | Typo |
| BUG-023 | ManageLegsAndMilestones.dart | 🟢 Low | Dead Code |
| BUG-024 | Multiple files | 🟢 Low | Performance |

---

## Recommended Fix Priority

### Fix Immediately (Critical — App Crashes)
1. BUG-001: ChatDetailScreen race condition
2. BUG-002: CourierMap null auth crash
3. BUG-003: Invalid zoom level 500.0 on map
4. BUG-004: Force unwrap on SQLite lookup
5. BUG-005: Unsafe Firestore cast in BrokerProfileScreen

### Fix Before Release (High — Features Broken)
6. BUG-006: BrokerMap countryCode crash
7. BUG-007: Asset loading crash
8. BUG-008: setState after dispose in milestone
9. BUG-009: CourierProfile spinner never shows
10. BUG-010: Missing mounted checks
11. BUG-011: Fire-and-forget Firebase calls

### Fix in Next Sprint (Medium — Silent Failures)
12–21: All medium severity bugs listed above

---

*Report generated by static code analysis on branch `development`*
