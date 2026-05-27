# 📱 Multi-Provider Installment Calculator

A premium, dark-themed utility application built using Flutter to help users calculate payment schedules, processing fees, and installment amounts across multiple popular Buy Now Pay Later (BNPL) services.

---

## ✨ Features

### 1. 🥥 Koko Calculator
*   **Installment Planner**: Quick calculation of 3-month installment plans.
*   **Find Shop Fee Tab**: A helper tool to calculate the hidden processing fee percentage charged by specific shops.
    *   Input raw item value and the final price shown on the shop's site to calculate the precise additional fee percentage.
    *   Reminders to verify whether delivery or extra costs are included.
    *   Highlights the default 6% secondary rate charged directly by Koko.

### 2. ⚡ PayZy Calculator
*   **Flexible Terms**: Calculate payments for 2, 3, or 4-month schedules.
*   **Customizable Fee**: Easily adjust the processing fee percentage (defaults to 8%) to see updated payment details instantly.

### 3. 🍃 MintPay Calculator
*   **3-Month Plans**: Calculate 3-month installment schedules.
*   **Customizable Fee**: Edit and apply specific installment/processing fees (defaults to 0%) for MintPay partners.

### 4. 🎨 Design & Theme
*   **Harmonious Dark Theme**: Sleek dark layout across all screens to protect the eyes.
*   **Vibe-Matched Branding**: Each provider screen uses accent colors matching their individual brand aesthetic (Koko's warm coconut tone, PayZy's vibrant electric pink, and MintPay's fresh mint green).
*   **Smart Hints**: Home page indicators reminding users that installment fees can vary depending on the merchant, suggesting they double-check with the store.

---

## 🌐 Web Application Access
This repository contains the built distribution of the Installment Calculator web application. 

To run this locally, you can serve this directory using any web server:
```bash
# Example using python's built-in server:
python -m http.server 8000
```
Then open `http://localhost:8000` in your web browser.
