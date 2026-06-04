# 📱 Multi-Provider Installment Calculator

A premium, dark-themed utility application built using Flutter to help users calculate payment schedules, processing fees, and installment amounts across multiple popular Buy Now Pay Later (BNPL) services in Sri Lanka.

---

## ✨ Features

### 🏠 Smart Dashboard
*   **Activity Overview**: See at-a-glance stats — total calculations, comparisons made, and a breakdown of your most-used provider.
*   **Recent History**: A unified feed of your last calculations across all providers, so you never lose track.
*   **Quick Actions**: Jump straight into any calculator, comparison tool, or shopping guide from the home screen.

### 💳 BNPL Calculators (All Providers in One Place)
Access all three provider calculators from a single organized hub.

#### 🥥 Koko
*   **Installment Planner**: Quick calculation of 3-month installment plans.
*   **Find Shop Fee Tab**: Calculate the hidden processing fee percentage charged by specific shops.
    *   Input the raw item value and the final price shown on the shop's site to calculate the precise additional fee.
    *   Highlights the default 6% secondary rate charged directly by Koko.
    *   Reminders to verify whether delivery or extra costs are included.

#### ⚡ PayZy
*   **Flexible Terms**: Calculate payments for 2, 3, or 4-month schedules.
*   **Customizable Fee**: Adjust the processing fee percentage (defaults to 8%) to see updated payment details instantly.

#### 🍃 MintPay
*   **3-Month Plans**: Calculate 3-month installment schedules.
*   **Customizable Fee**: Edit and apply specific installment/processing fees (defaults to 0%) for MintPay partners.

---

### ⚖️ Provider Comparison Tool
*   **Side-by-Side Comparison**: Enter a single purchase amount and instantly compare the total cost, monthly payment, and fees across Koko, PayZy, and MintPay.
*   **Custom Fee Overrides**: Adjust individual provider fees before comparing to reflect real shop-specific rates.
*   **Cheapest Option Highlight**: The app automatically flags which provider costs the least for your specific purchase.

---

### 🛒 BNPL Shopping Guide
*   **How BNPL Works**: A clear, beginner-friendly explanation of the buy-now-pay-later model.
*   **Provider-Specific Tips**: Practical advice for getting the best deal with each provider (Koko, PayZy, MintPay).
*   **Common Pitfalls**: Warnings about hidden fees, shop surcharges, and what to double-check before committing.
*   **FAQs**: Answers to the most common questions about BNPL in Sri Lanka.

---

### 🎨 Design & Theme
*   **Harmonious Dark Theme**: Sleek dark layout across all screens to protect the eyes.
*   **Vibe-Matched Branding**: Each provider screen uses accent colors matching their individual brand aesthetic (Koko's warm coconut tone, PayZy's vibrant electric pink, and MintPay's fresh mint green).
*   **Premium UI**: Glassmorphism cards, smooth animations, and micro-interactions throughout.

---

## 🚀 Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your system.

### Running Locally
Run the app in debug mode on an emulator, connected device, or web browser:
```bash
flutter run
```

### Building for Production

#### 🌐 Web Version (for iOS and browser users)
```bash
flutter build web --release --no-tree-shake-icons
```
The compiled static website will be generated in the `build/web` directory, ready to be hosted on GitHub Pages or Netlify.

#### 🤖 Android APK
```bash
flutter build apk --split-per-abi --release
```
Split APKs will be generated at `build/app/outputs/flutter-apk/`.

---

## 🌐 Web App

The web version is live and accessible at:
**[https://dmstyles.github.io/installment-calculator](https://dmstyles.github.io/installment-calculator)**

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
