# NOTICE: modifications to RustDesk 1.5.3

This program is a modified version of RustDesk 1.5.3 (https://github.com/rustdesk/rustdesk, tag 1.5.3; submodule hbb_common fae47e0).
Copyright © RustDesk contributors. License of the whole work: GNU AGPL-3.0 (`LICENCE`).
Modified by New Age Software Inc. / ETTC (eshopservices.gr). The first commit in this repository is the unmodified upstream source. The second commit has all of our changes.

## 21/11/2026 (Floanta Desk, sideload build)
- The app reads the server host and public key from `floanta_server.json` in the APK, and these take priority over the saved setting. If the file exists but is invalid, the app does not connect to the public RustDesk servers.
- The sideload build checks the eshopservices notify service for a newer version and offers to install it. The RustDesk upstream updater is not used on Android.

## 22/11/2026 (Floanta Support, Google Play build)
- App name is Floanta Support and applicationId is `floanta.support`. The Kotlin/Java namespace stays `com.carriez.flutter_hbb`. User-visible "RustDesk" wording is replaced, but the RustDesk attribution in About stays.
- The server is the hostname `supportservice.floanta.com` instead of a fixed IP. The relay is provided by hbbs.
- The Play build (`FLOANTA_PLAY` / `floantaPlay`) has no `REQUEST_INSTALL_PACKAGES` permission and no self-updater.
- A prominent disclosure screen (Greek/English, by device locale) is shown before Accessibility settings open. Accept opens them. Decline does not, and view-only support still works.
- A step-by-step guide covers the three permissions: Accessibility, screen capture, and display over other apps. It shows each one's status and has a settings button for each.
- `android.hardware.microphone` is `required=false`.
- The deep link scheme is `floantasupport://`.
- Version 0.1.0, versionCode 1, targetSdk 36.
- Play `minSdkVersion` is 24, as required by Play automatic protection.
- The launcher and adaptive icons are the Floanta Support icon, background color `#0F6E56`.
- The Rust library app name is "Floanta Support".
- The Play build does not automatically open the log-folder or file-transfer folder picker when the service starts. File transfer and log-folder access are only requested if the user later needs them.
- The Play build hides Settings › Account › Login (and other account login/signup entry points).

---

# Αλλαγές πάνω στο RustDesk 1.5.3 (ελληνικά)

Ημερομηνία: 22/11/2026. Άδεια του συνόλου: GNU AGPL-3.0, όπως το πρωτότυπο (`LICENCE`). Η απόδοση πνευματικών δικαιωμάτων στο RustDesk μένει στο About και σε αυτό το σημείωμα.

- Εφαρμογή Play: όνομα Floanta Support, applicationId `floanta.support`. Ο χώρος ονομάτων Kotlin/Java μένει `com.carriez.flutter_hbb`.
- Server: `supportservice.floanta.com` από το `floanta_server.json`. Το relay έρχεται από τον hbbs.
- Έκδοση Play 0.1.0 (versionCode 1). targetSdk 36.
- Χτίσιμο Play (`FLOANTA_PLAY` / `floantaPlay`): χωρίς `REQUEST_INSTALL_PACKAGES` και χωρίς τον έλεγχο ενημέρωσης στο notify. Το sideload APK μένει ως έχει.
- Οθόνη γνωστοποίησης (ελληνικά ή αγγλικά, κατά τη γλώσσα της συσκευής) πριν ανοίξουν οι ρυθμίσεις προσβασιμότητας. Αποδοχή τις ανοίγει, Απόρριψη όχι. Η προβολή χωρίς χειρισμό παραμένει δυνατή.
- Οδηγός για τις τρεις άδειες: προσβασιμότητα, καταγραφή οθόνης, εμφάνιση πάνω από άλλες εφαρμογές, με κατάσταση και κουμπί ρυθμίσεων.
- `android.hardware.microphone` με `required=false`.
- Σχήμα συνδέσμου: `floantasupport://`.
- Play: `minSdkVersion` 24, όπως απαιτεί η αυτόματη προστασία του Play.
- Launcher και adaptive icon Floanta Support, χρώμα φόντου `#0F6E56`.
- Το όνομα της εφαρμογής στο Rust lib είναι «Floanta Support».
- Στο Play build δεν ανοίγει αυτόματα, στην έναρξη υπηρεσίας, ο picker φακέλου για αρχεία καταγραφής ή μεταφορά αρχείων.
- Στο Play build είναι κρυμμένη η επιλογή Ρυθμίσεις › Λογαριασμός › Σύνδεση.
