# QueuEx Mobile App — Developer & UI Reference

Flutter app for **students**. Staff use a separate React dashboard
(documented in `STAFF_FRONTEND_DOCUMENTATION.md` in that repo).

This document is written for someone picking up UI work without having
built the app. It covers what each screen does, how navigation flows, the
existing design system, and where the constraints are — so an enhancement
doesn't accidentally break a rule the rest of the system depends on.

---

## 1. What this app is for

A student registers their face once, then taps **Join the Queue** when they
actually want a number. When they walk in front of the queue-area camera,
the system recognises them and issues their queue number automatically —
no kiosk button, no staff typing.

Two things follow from that, and both matter for UI work:

- **The app is not what issues the number.** The camera does. The app
  arms the request and then displays live status. Copy should never imply
  tapping a button produces a ticket immediately.
- **Recognition is not consent.** A student is only issued a number if they
  tapped Join first. Any UI change that makes Join easy to skip, or unclear,
  breaks a deliberate privacy protection.

Walk-ins (people without an account) still use the physical kiosk. The app
supports them only through the **ticket-lookup** flow, where they type or
scan a printed ticket to track it.

---

## 2. Two independent session types

This trips people up, so read this before touching navigation.

| | `StudentSessionStore` | `QueueSessionStore` |
|---|---|---|
| Who | A registered student | Anyone holding a printed ticket |
| Auth | Google (Gbox) or face login | Queue number + access token |
| Persists across app restart | **Yes** (`shared_preferences`) | **Yes** |
| Identifies a person | Yes | No — identifies a *ticket* |
| Check | `StudentSessionStore.isLoggedIn` | `QueueSessionStore.hasSession` |

These are **independent**. A student can be logged in with or without an
active ticket; a guest can track a ticket with no account at all. Several
screens read both to decide what to render — `profile_screen.dart` is the
clearest example ("Log out of my account" vs "Clear ticket").

---

## 3. Navigation map

`main.dart` holds the route table. `/` is `_BootstrapScreen`, which decides
where a cold start lands:

```
app launch
   └─ _BootstrapScreen
        ├─ student session restored?
        │     ├─ face registered      → /student/home
        │     └─ no face yet          → /student/face-capture
        ├─ guest ticket session restored? → live queue screen
        └─ nothing                    → /student/login
```

### Route table

| Route | Screen file | Purpose |
|---|---|---|
| `/` | `main.dart` (`_BootstrapScreen`) | Decides landing screen |
| `/student/login` | `student_login_screen.dart` | Entry point |
| `/student/school-id` | `school_id_screen.dart` | One-time school-ID capture |
| `/student/face-capture` | `face_capture_screen.dart` | Guided face enrollment |
| `/student/home` | `student_home_screen.dart` | Student dashboard |
| `/ticket/lookup` | `login_screen.dart` | Guest ticket lookup |
| `/queue/waiting` | `queue_waiting_screen.dart` | Live queue status |
| `/queue/next` | `youre_next_screen.dart` | You're next |
| `/queue/noshow` | `no_show_warning_screen.dart` | No-show countdown |
| `/queue/complete` | `service_complete_screen.dart` | Post-service summary |
| `/queue/exit` | `exit_notification_screen.dart` | Session ended |
| `/history` | `history_screen.dart` | Past/current ticket |
| `/profile` | `profile_screen.dart` | Account & settings |
| `/help` | `help_screen.dart` | How it works |

Note `login_screen.dart` is the **ticket-lookup** screen despite its name —
`student_login_screen.dart` is the actual login. Renaming would be welcome
but touches many call sites.

Two screens have **no route** and are pushed directly, returning a value:

- `face_scan_screen.dart` — live face login, pops a `File?`
- `qr_scanner_screen.dart` — QR scan, pops a `String?`

### Back-button rule

Every screen has a back button **except `/student/login` and
`/student/home`** — both are root screens with nothing meaningful behind
them.

Back destinations are **explicit, not `Navigator.pop()`**. Most transitions
use `pushReplacementNamed` (the queue screens auto-navigate between
themselves as status changes), so there is often no stack to pop. Each
screen passes an explicit destination:

```dart
QAppBar(
  title: 'History',
  showBack: true,
  onBack: () => Navigator.of(context).pushReplacementNamed('/student/home'),
)
```

**If you add a screen, wire `onBack` explicitly.** Relying on `pop()` will
silently do nothing on most paths.

---

## 4. Screens

### `/student/login` — Student Login
Entry point. No back button.

- **Log in with Face** (primary) → pushes `FaceScanScreen`, gets a photo, sends to `/api/students/auth/face`
- **Sign in with Gbox** (secondary) → Google sign-in
- **Create an account** (below a "NEW HERE?" divider) → same Google flow; first-time sign-in is detected server-side and redirects to school-ID capture
- **"Just tracking a printed ticket?"** (smallest, bottom) → `/ticket/lookup`

Sign-up and sign-in are the *same* Google call. The backend returns a
`school_id_required` error on first sign-in, which the app catches and turns
into a redirect. Don't "simplify" these into one button — the visual
separation is the only signal a new user gets.

The app clears the cached Google account before every prompt, so the
account picker always appears. Without that, a student who picked a
personal (non-Gbox) account by mistake could never switch.

### `/student/school-id` — School ID
One-time form after first Google sign-in. Pops the entered ID back to the
login screen, which retries auth with it. Back = cancel sign-up.

### `/student/face-capture` — Face Enrollment
Guided auto-capture. **No shutter button.** Three poses: centre, turn one
way, turn back the other. Google ML Kit reports head angle, face size, and
frame brightness; the app captures automatically once the pose holds for 8
good frames.

Live prompts: *"Look straight at the camera"*, *"Move a little closer"*,
*"Too dark — move somewhere brighter"*, *"Hold still…"*. The circular
preview border turns green when aligned.

A "take this shot manually" fallback exists for when auto-capture fails.
**Keep it.** It is the only escape hatch if the guided flow doesn't work on
someone's device.

Only the three photos are uploaded; the backend derives a face signature
and discards the images.

### `/student/home` — Student Dashboard
The main screen. No back button. Pull-to-refresh, polls every 5s.

Sections top to bottom:
1. **Identity card** — name, school ID, "Face registered" / "Face not set up" badge
2. **QUEUE RIGHT NOW** — three stat tiles: in line, wait if you arrive now, counters open
3. **YOUR STATUS** — one of:
   - Face not registered → amber banner + "Register My Face"
   - Not joined → **Join the Queue** button
   - Joined → green "You're in" banner + **Cancel — I'm not queueing**
   - Camera has seen them → "confirming your identity now…"
4. **WHAT YOU CAN DO** — how it works, plus "Track a printed ticket"
5. **Log Out**

The 5s poll auto-navigates to the live queue screen the moment a number is
issued. It deliberately **does not** navigate into an already-finished
session — that caused a dashboard ↔ "session ended" loop.

### `/ticket/lookup` — Guest Ticket Lookup
Queue number + access token, or **Scan Ticket QR** (pushes `QrScannerScreen`).
Starts a `QueueSessionStore` session and routes to the right live screen.

### Live queue screens
Four screens for one journey. The app moves between them automatically as
status changes — the student never picks one.

| Screen | State | Poll | Distinct UI |
|---|---|---|---|
| `/queue/waiting` | In line | 6s | Number, position, line ahead |
| `/queue/next` | You're next | 5s | **Green** app bar, "I'm on my way" button |
| `/queue/noshow` | About to be bumped | 3s | **Amber** app bar, countdown bar |
| `/queue/exit` | Session ended | — | Dimmed card, "Got it, I'm leaving" |
| `/queue/complete` | Summary | — | Total wait, served time, counter |

Colour is the primary state signal here (green = go, amber = warning). Keep
that mapping if restyling.

"Got it, I'm leaving" returns a signed-in student to `/student/home`, and a
guest to `/ticket/lookup`.

### `/history`, `/profile`, `/help`
Reached via the bottom nav. History shows the current/most recent ticket.
Profile shows identity and a combined logout/clear-ticket action that
behaves differently for students vs guests. Help is static explanatory cards.

---

## 5. Design system

`lib/theme/app_theme.dart` holds `AppColors`. Colours are grouped by
meaning, and the semantics are load-bearing:

| Family | Use |
|---|---|
| `dark` `#1A1A2E` | App bars, primary buttons, headings |
| `purple` family | Brand, neutral info, active nav |
| `green` family | Success, "you're next", confirmed |
| `amber` family | Warning, no-show, face not set up |
| `red` family | Errors |
| `bg` `#F4F4F8` | Page background |
| `border` / `textMuted` / `textLight` | Structure and secondary text |

**There is no `TextTheme`.** Every `Text` hard-codes `fontSize` and
`fontWeight`, ranging roughly 9–44px. Introducing a proper type scale is
the single highest-value UI improvement available, and it would touch every
screen.

### Shared widgets — `lib/widgets/shared_widgets.dart`

| Widget | Purpose |
|---|---|
| `QAppBar` | App bar. Params: `title`, `bgColor`, `logoColor`, `showBack`, `onBack`, `actions` |
| `QBottomNavBar` | 4 tabs (My Queue / History / Profile / Help), custom-painted icons |
| `PrimaryButton` | Main button, `outlined: true` for secondary |
| `QBadge` | Small status pill |
| `StatTile` | Stat in a row (expands to fill) |
| `QueueListItem` | Row with circular leading badge |
| `AlertBanner` | Coloured banner with dot |
| `QueueNumberCard` | Large queue number display |
| `SectionLabel` | Small uppercase section heading |

**Prefer extending these over adding one-off styling.** They are what keeps
the app visually coherent.

### Layout conventions
- Page padding: `EdgeInsets.fromLTRB(20, 16, 20, 28)`
- The extra bottom padding clears the device gesture bar
- `QBottomNavBar` adds `MediaQuery.viewPaddingOf(context).bottom` itself —
  a `SafeArea` in the page body does **not** cover it, because Scaffold
  places the nav bar outside the body

---

## 6. Services

| File | Responsibility |
|---|---|
| `api_config.dart` | Base URL. Override: `--dart-define=QUEUEFLOW_API_BASE_URL=http://<ip>:5000` |
| `student_api.dart` | Student endpoints (auth, face, join, queue status) |
| `queue_api.dart` | Ticket endpoints (lookup, status, QR parsing) |
| `student_session_store.dart` | Student session + Google sign-in |
| `queue_session_store.dart` | Ticket session + snapshot polling |
| `queue_navigation.dart` | Maps a snapshot to the right route |
| `camera_ml_kit.dart` | Camera frame → ML Kit input, brightness sampling |

### Error handling conventions

`QueueApiException` carries a user-safe message and is caught specifically
by screens. `SchoolIdRequiredException` is control flow, not an error —
**it must be rethrown, never swallowed.**

**Do not add broad `catch (_)` blocks.** Two of this app's worst bugs came
from exactly that: a swallowed `SchoolIdRequiredException` broke sign-up,
and a catch-all turned every failure into a false "Cannot reach QueuEx API"
message that sent debugging in the wrong direction for hours. Catch
specifically, or let it propagate.

---

## 7. Running it

```bash
flutter pub get
flutter run -d <device> --dart-define=QUEUEFLOW_API_BASE_URL=http://<pc-lan-ip>:5000
flutter analyze     # keep clean
flutter test        # 6 tests
```

The backend must be reachable from the phone — same network, and the LAN
IP, not `localhost`.

---

## 8. Rules an enhancement must not break

1. **Join is consent.** Don't remove it, auto-tap it, or make it skippable.
2. **Login and Home have no back button.** Everything else does.
3. **`onBack` must be explicit.** `pop()` silently does nothing on most paths.
4. **Don't auto-navigate into a finished session** — causes an infinite loop.
5. **Keep the manual-capture fallback** on the enrollment screen.
6. **Don't imply the app issues numbers.** The camera does.
7. **No broad `catch (_)`.** Catch specific exceptions or let them propagate.
