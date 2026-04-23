<div align="center">

# Lumina

**An iPadOS & iOS app that lets you explore your 24 VIA character strengths with a private, on-device AI companion.**

Built with SwiftUI, SwiftData, and Apple Foundation Models (iOS 26) — no servers, no accounts, no analytics.

[![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-0A84FF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/SwiftData-FF6F61?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/documentation/swiftdata)
[![Foundation Models](https://img.shields.io/badge/Foundation_Models-5E5CE6?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/documentation/foundationmodels)
[![iOS](https://img.shields.io/badge/iOS-26.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/ios)
[![iPadOS](https://img.shields.io/badge/iPadOS-26.0+-000000?style=for-the-badge&logo=apple&logoColor=white)](https://www.apple.com/ipados)
[![Xcode](https://img.shields.io/badge/Xcode-26-1575F9?style=for-the-badge&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)

[![Apple Intelligence](https://img.shields.io/badge/Apple_Intelligence-on--device-0A84FF?style=flat-square)](https://www.apple.com/apple-intelligence/)
[![Privacy](https://img.shields.io/badge/Privacy-no_data_collected-34C759?style=flat-square)](#privacy)
[![Accessibility](https://img.shields.io/badge/Accessibility-VoiceOver_ready-5E5CE6?style=flat-square)](#accessibility)
[![Localization](https://img.shields.io/badge/Locale-es--MX-FF9500?style=flat-square)]()

</div>

---

## About

Lumina is a production iPadOS/iOS app I designed and built end-to-end for **Colegio Walden Dos** (Mexico). It administers the 48-question **VIA Character Strengths** assessment (Peterson & Seligman, 2004) and uses Apple's on-device Foundation Models to generate personalized reflections, a daily micro-insight, and an AI companion chat — all without leaving the device.

It's an exercise in what modern iOS can do when you lean fully into the platform: `@Model`-backed persistence, `@Generable` structured output from a local LLM, Swift concurrency streaming, Dynamic Type down to AX5, and a design system that stays consistent from splash to settings.

---

## Screenshots

<table>
  <tr>
    <td align="center"><img src="assets/screenshots/iphone/01-my-strengths.png" width="260" alt="Mis 24 — top 3 strengths at a glance" /><br /><sub><b>Mis 24</b><br />Top 3 at a glance + daily reflection</sub></td>
    <td align="center"><img src="assets/screenshots/iphone/02-personalized-insight.png" width="260" alt="Personalized AI analysis" /><br /><sub><b>Personalized analysis</b><br />On-device LLM, structured output</sub></td>
    <td align="center"><img src="assets/screenshots/iphone/03-evolution.png" width="260" alt="Evolution charts" /><br /><sub><b>Evolution</b><br />Top-5 trajectory across tests</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="assets/screenshots/iphone/06-buddy-chat.png" width="260" alt="Buddy — AI companion chat" /><br /><sub><b>Buddy</b><br />Streaming chat, markdown, suggestions</sub></td>
    <td align="center"><img src="assets/screenshots/iphone/07-conversations.png" width="260" alt="Conversation history" /><br /><sub><b>Conversations</b><br />Auto-renamed with AI, ChatGPT-style</sub></td>
    <td align="center"><img src="assets/screenshots/iphone/09-quiz.png" width="260" alt="48-question VIA quiz" /><br /><sub><b>Test</b><br />48 items, 5-point Likert, narrated</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="assets/screenshots/iphone/04-stories.png" width="260" alt="Stories journal" /><br /><sub><b>Stories</b><br />Strength-tagged moments</sub></td>
    <td align="center"><img src="assets/screenshots/iphone/05-story-detail.png" width="260" alt="Story detail with read-aloud" /><br /><sub><b>Story detail</b><br />Read-aloud via AVSpeechSynthesizer</sub></td>
    <td align="center"><img src="assets/screenshots/iphone/08-settings.png" width="260" alt="Settings" /><br /><sub><b>Settings</b><br />AI personality, accessibility, notifications</sub></td>
  </tr>
</table>

<details>
<summary><b>iPad screenshots</b> (tap to expand)</summary>
<br />
<table>
  <tr>
    <td><img src="assets/screenshots/ipad/page-01.png" width="360" alt="iPad — Mis 24" /></td>
    <td><img src="assets/screenshots/ipad/page-02.png" width="360" alt="iPad — Personalized analysis" /></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/ipad/page-03.png" width="360" alt="iPad — Evolution" /></td>
    <td><img src="assets/screenshots/ipad/page-04.png" width="360" alt="iPad — Stories" /></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/ipad/page-05.png" width="360" alt="iPad — Story detail" /></td>
    <td><img src="assets/screenshots/ipad/page-06.png" width="360" alt="iPad — Buddy" /></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/ipad/page-07.png" width="360" alt="iPad — Conversations" /></td>
    <td><img src="assets/screenshots/ipad/page-08.png" width="360" alt="iPad — Settings" /></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img src="assets/screenshots/ipad/page-09.png" width="360" alt="iPad — Test" /></td>
  </tr>
</table>
</details>

---

## Tech stack

| Layer | Technology |
| --- | --- |
| **Language** | Swift 6 (strict concurrency, `@Observable`) |
| **UI** | SwiftUI (iOS 26), custom design system, Liquid Glass material |
| **Persistence** | SwiftData (`@Model`, cascading relationships, `#Predicate` queries) |
| **On-device AI** | Foundation Models framework (`LanguageModelSession`, `@Generable`, guided generation, streaming) |
| **Concurrency** | Swift Structured Concurrency, `AsyncThrowingStream`, `@MainActor` actors |
| **Accessibility** | VoiceOver labels, Dynamic Type up to AX5, `AVSpeechSynthesizer` narration |
| **Localization** | String Catalogs (`Localizable.xcstrings`, es-MX) |
| **Charts** | Swift Charts (Swift 6 Chart API) |
| **Privacy** | `PrivacyInfo.xcprivacy`, zero tracking, Required-Reason APIs declared |

---

## What makes it interesting

### 1. On-device LLM with structured output

The personalized analysis isn't a paragraph of free text — it's a `@Generable` Swift struct (signature strengths, growth areas, weekly actions, encouragement) decoded by Apple's Foundation Models framework against a Spanish-language prompt. The model runs entirely on the Neural Engine; nothing leaves the device.

```swift
let response = try await session.respond(
    to: userPrompt,
    generating: StrengthInsight.self
)
return response.content
```

### 2. ChatGPT-style streaming companion with defensive safety

The Buddy tab streams responses token-by-token through an `AsyncThrowingStream`, auto-renames the conversation after the first exchange (like ChatGPT), and persists everything in SwiftData with **lazy creation** — conversations don't hit the store until the user sends a message, so the history never fills with empty drafts.

On top of that, every prompt passes through a **deterministic Swift-side safety filter** before reaching the LLM. Medical, mental-health crisis, and substance-use keywords short-circuit the model and return a canned redirect to a qualified professional (including Mexican crisis helplines). Prompt instructions alone are not a reliable guarantee — the filter closes that gap for App Review 1.4.1 regardless of how creative the user gets.

### 3. Designed for App Store review

The app shipped through Apple's rejection–resubmission cycle and now explicitly handles **Guideline 1.4.1** (health/medical content): disclaimers in onboarding, a permanent Settings screen, inline banners under every AI surface, tappable APA-7 citations that open the primary sources (VIA Institute, DOI of Park et al. 2004, Oxford University Press, Hogrefe), and the deterministic safety filter mentioned above.

### 4. Graceful degradation

Apple Intelligence is iOS 26 only, and not every device is eligible. `AICapabilityGate` detects availability up front; on unsupported devices the Buddy tab and AI-generated cards are hidden cleanly, and the user still gets the full 48-question test + ranked strengths + stories journal.

### 5. Accessibility is not an afterthought

- Tap targets ≥ 44×44 even when the glyph is small (hit-area expansion without visual scaling).
- `AVSpeechSynthesizer` read-aloud on quiz questions, results, stories, and onboarding — with `.playback + .duckOthers` audio session so narration works with the silencer switch on, but never plays in the background.
- Dynamic Type capped per screen to prevent AX5 overflow on pages with hero display fonts.
- VoiceOver labels, structured headers, combined accessibility elements on cards.

### 6. Zero data collection

- `PrivacyInfo.xcprivacy` declares zero tracking, zero collected data, and explicit Required-Reason APIs.
- No cloud backend, no third-party SDKs, no analytics.
- Photos for stories go through `PhotosPicker` (sandboxed), saved to the app container and deleted with the story.

---

## Architecture

```
Lumina/
├── App/                      # App entry, RootView, tab coordinator
├── Core/
│   ├── AI/                   # FoundationModelsProvider, Buddy service, safety filter
│   ├── Accessibility/        # ReadAloudButton, narration service
│   ├── Catalog/              # 24 VIA strengths + 48 questions (source of truth)
│   ├── DesignSystem/         # Theme, CardContainer, LuminaButton/Chip/SectionHeader
│   ├── Models/               # SwiftData @Model types
│   ├── Notifications/        # Local UNUserNotificationCenter scheduling
│   ├── Persistence/          # ModelContainer factory
│   ├── QuickActions/         # Home-screen 3D-touch shortcuts
│   └── Review/               # SKStoreReviewController gating
├── Features/
│   ├── Buddy/                # AI chat tab — streaming, auto-rename, safety
│   ├── Legal/                # Privacy policy, References, About this app
│   ├── Onboarding/           # 6-step flow, conditional Apple Intelligence page
│   ├── Quiz/                 # 48-item test, Likert pills, processing animation
│   ├── Results/              # Mis 24, Insights, Evolution charts
│   ├── Settings/             # Accessibility, AI personality, notifications
│   ├── Splash/               # Random-bear splash with shimmer
│   └── Stories/              # Journal tagged by strength
└── Localizable.xcstrings     # All user-facing strings (es-MX)
```

**Dependency injection via SwiftUI environment.** The `AIInsightsProviding` protocol lets the app use the real Foundation Models implementation on-device and swap in a mock for previews/tests without touching call sites.

**File-system-synchronized project.** Uses `PBXFileSystemSynchronizedRootGroup` (new in Xcode 16) so adding a `.swift` file in Finder is enough — no pbxproj churn, fewer merge conflicts.

---

## Requirements

- **iOS / iPadOS 26.0+** (required for Foundation Models)
- **Xcode 26**
- Apple Intelligence-eligible device for AI features (iPhone 15 Pro / 16 / 17 series, iPad M1 and later). The rest of the app runs everywhere.

---

## About the author

I'm **Christian Arzaluz** — iOS engineer based in Mexico. Lumina is a real, shipping client project; the source is public for portfolio purposes.

- GitHub: [@arzaluz-chris](https://github.com/arzaluz-chris)
- Email: christian.arzaluz@gmail.com

If you're hiring for iOS / SwiftUI / on-device AI work, I'd love to talk.
