# CyphLab Flutter Expense Tracker Internship Task

A clean, modern, and highly interactive Expense Tracker mobile application built with Flutter and Firebase Firestore. This project was developed as part of the CyphLab Flutter Developer Internship selection process.

## 🚀 Features Implemented
* **Real-time Database:** Stores and syncs all expenses using Firebase Firestore (`StreamBuilder`) instantly across the app.
* **CRUD Operations:** Seamlessly add, edit, and delete expenses through a beautiful, centered pop-up dialog.
* **Advanced Filtering & Search:** 
  * Real-time text search for expense titles.
  * Time-based filtering (This Month, Last Month, All Time).
  * Quick-access horizontal category chips.
* **Month-over-Month Comparison:** Dynamically compares current month spending with the previous month and visually indicates trends (▲ more / ▼ less).
* **Theme Customization:** Toggle between Light and Dark mode with a seamless, animated processing transition.
* **Splash Screen:** Beautiful animated splash screen with a custom brand logo on startup.
* **Category Dashboard & Breakdown:** Summary screen showcasing category-wise expenses with intuitive donut charts, progress bars, and percentage calculations.
* **Form Validation:** Strict input validation for titles, amounts, and ensuring data integrity.
* **Sample Data Generator:** Includes a hidden tool in the AppBar to instantly wipe old data and seed the database with 40 realistic sample entries in LKR (Rs.) for easy testing.
* **No Authentication Required:** Directly opens the app for quick and easy expense logging.

## 🛠️ Technologies & Packages Used
* **Framework:** Flutter (Dart)
* **Backend & Database:** Cloud Firestore (Firebase Core & Firestore)
* **Formatting:** `intl` package for clean currency and date formatting.

## 🤖 AI Tools Used During Development
During the development of this task, the following AI tools were effectively utilized to enhance code quality, UI layout, and architecture:
* **Claude AI:** Used for designing clean, modern, responsive frontend UI components, user screens, and base configurations.
* **Gemini (Google DeepMind):** Used for advanced logic integration, complex state management (filtering, popups), Firebase Firestore stream configurations, dynamic month-on-month calculations, and debugging data flows.

## 📱 Project Setup & Installation Instructions
1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd <your-repository-name>
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Connect to Firebase (If required):**
   This project uses Firebase. Ensure you have your `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) configured correctly if linking to a new Firebase environment.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🎥 Video Demonstration
* [Insert Google Drive / YouTube Unlisted Link Here]

## 📦 Release Build / APK
* [Insert APK download link here]
