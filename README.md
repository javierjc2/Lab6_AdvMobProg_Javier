# javier_advmobprog

NUBD Exchange – Advanced Mobile Programming (Flutter).

## Running the project

```bash
flutter pub get
flutterfire configure        # pick YOUR Firebase project -> overwrites lib/firebase_options.dart
flutter run
```

Firebase Console checklist: enable **Authentication → Email/Password** and create a
**Firestore Database**; paste `firestore.rules` into the Firestore *Rules* tab.

---

## Lab Activity 5: discussion

### Workflow: DummyJSON vs Firebase (signIn → signUp)

The Sign In screen has a **DummyJSON / Firebase** toggle. The choice is saved as a
`LoginType` so the rest of the app knows which backend owns the session.

**DummyJSON (REST)**
1. User enters a DummyJSON username + password.
2. `UserService.loginUser()` POSTs to `https://dummyjson.com/auth/login`.
3. The response (profile + `accessToken` / `refreshToken`) is saved to SharedPreferences
   with `loginType = dummyJson`.
4. There is no real sign-up: DummyJSON has no registration endpoint, and its update/delete
   endpoints only *simulate* the change.

**Firebase (SDK)**
1. **Sign up** (`signup_screen.dart`): the user fills in fName, lName, age, contactNo,
   username, email and a validated password. `UserService.registerWithProfile()` calls
   `createUserWithEmailAndPassword`, sets the display name, and writes the profile to
   Firestore at `users/{uid}`.
2. **Sign in**: `UserService.signIn()` → `signInWithEmailAndPassword`. The SDK stores the
   session itself and silently refreshes the 1-hour ID token with a refresh token
   (`getIdToken(true)` forces a refresh).
3. **Persistent login**: on launch the Splash screen asks `isLoggedIn()`. For Firebase this
   is `authStateChanges().first` (non-null = session restored); for DummyJSON it checks the
   saved token.
4. **Profile**: `getUserData()` merges `FirebaseAuth.currentUser` with the Firestore document.
5. **Account actions**: `updateUsername`, `resetPasswordFromCurrentPassword` and
   `deleteAccount` (the last two re-authenticate first, as Firebase requires for
   sensitive operations).
6. **Logout** (Profile and Settings): `UserService.logout()` signs out of Firebase, clears
   SharedPreferences, the cart is cleared, and the app returns to Sign In.

### Main idea of `UserService`

`UserService` is the single place where every authentication and account concern lives. Screens
never talk to `http`, `FirebaseAuth`, Firestore or SharedPreferences directly; they call
methods like `signIn`, `createAccount`, `getUserData` and `logout`. Because both backends
return the same user map (and a `User` model with a `LoginType`), the UI (Splash, Home,
Profile) works unchanged for either one. This keeps screens thin and makes it easy to
swap or add a backend.

### Benefits of the Firebase implementation

- **Real accounts**: real sign-up, email/password and password change/delete, which DummyJSON can only simulate.
- **Secure by default**: passwords are never stored by the app; tokens are managed and
  refreshed by the SDK; Firestore security rules ensure a user can only read/write their own profile.
- **Persistent sessions with no extra code** and automatic token refresh.
- **Cloud-stored profile data** (age, contact number, …) available on any device.
- **Less backend work**: no server to build or maintain, and it scales automatically.
