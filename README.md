# 🩸 LIFEDROP - Smart Blood Donation Management System

LIFEDROP is a modern, mobile-based solution designed to bridge the gap between blood donors and those in urgent need. Built using **Flutter** and **Firebase**, it simplifies the process of finding donors, managing donation campaigns, and tracking donor eligibility in real-time.

---

## 🚀 Key Features

### For Donors
* **Eligibility Tracker:** Automatically calculates the 90-day waiting period between donations.
* **Digital Donor ID & QR Pass:** Securely generates a unique QR code for quick check-ins at donation camps.
* **Appointment Booking:** Browse and book slots for upcoming blood donation campaigns.
* **Smart Matching:** Get real-time notifications for urgent blood requests matching your blood type.
* **Donation History:** Keep a detailed log of your past donations and impact.

### For Administrators
* **Campaign Management:** Create and manage blood donation drives.
* **Request Verification:** Review and verify urgent blood requests.
* **Donor Database:** Maintain an organized, searchable database of active donors.

---

## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev/) (Dart)
* **Backend/Database:** [Firebase](https://firebase.google.com/) (Firestore, Authentication, Cloud Messaging)
* **Architecture:** Clean Architecture with Provider State Management
* **Maps API:** Google Maps Integration for location-based donor search

---

## ⚙️ Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/YourUsername/lifedrop-blood-donation-app.git](https://github.com/YourUsername/lifedrop-blood-donation-app.git)
    ```
2.  **Navigate to the project directory:**
    ```bash
    cd lifedrop-blood-donation-app
    ```
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Firebase Setup:**
    * Create a new project on [Firebase Console](https://console.firebase.google.com/).
    * Add Android/iOS apps and download `google-services.json` or `GoogleService-Info.plist`.
    * Place them in the respective `android/app` or `ios/Runner` folders.
5.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 🛡️ Security & Privacy
* User authentication managed via Firebase Auth.
* Strict data privacy for donor contact information.
* Role-based access control for Admins and Donors.

---

## 🔮 Future Enhancements
* AI-based prediction for blood shortage in specific regions.
* Integration with government hospital APIs for verified medical records.
* In-app community forum for blood donation awareness.

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.

**Developed with ❤️ by Chamodi Sandeepani**
