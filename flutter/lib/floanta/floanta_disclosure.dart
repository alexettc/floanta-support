import 'dart:ui' as ui;

import 'package:flutter/material.dart';

bool floantaDeviceGreek() {
  return ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase() ==
      'el';
}

String floantaDisclosureTitle() {
  return floantaDeviceGreek()
      ? 'Πρόσβαση για απομακρυσμένο χειρισμό'
      : 'Access for remote control';
}

String floantaDisclosureBody() {
  if (floantaDeviceGreek()) {
    return 'Το Floanta Support χρησιμοποιεί την υπηρεσία προσβασιμότητας μόνο για να εκτελεί απομακρυσμένο άγγιγμα και πληκτρολόγιο, κατά τη διάρκεια συνεδρίας υποστήριξης που εσείς εγκρίνετε.\n\n'
        'Δεδομένα: περιεχόμενο οθόνης και εισαγωγή (άγγιγμα, πληκτρολόγιο).\n\n'
        'Στέλνονται μόνο μέσω της κρυπτογραφημένης συνεδρίας στον συνδεδεμένο τεχνικό. Δεν τα αποθηκεύουμε, δεν τα χρησιμοποιούμε για διαφημίσεις και δεν τα μοιραζόμαστε.\n\n'
        'Αποδοχή ανοίγει τις ρυθμίσεις προσβασιμότητας. Απόρριψη δεν τις ανοίγει. Η συνεδρία μόνο προβολής παραμένει δυνατή.';
  }
  return 'Floanta Support uses the Accessibility service only to perform remote touch and keyboard input during a support session you authorized.\n\n'
      'Data involved: screen content and input (touch and keyboard).\n\n'
      'It is sent only over the encrypted session to the paired technician. We do not store it, we do not use it for ads, and we do not share it.\n\n'
      'Accept opens Accessibility settings. Decline does not. A view-only session is still possible.';
}

String floantaAcceptLabel() => floantaDeviceGreek() ? 'Αποδοχή' : 'Accept';

String floantaDeclineLabel() => floantaDeviceGreek() ? 'Απόρριψη' : 'Decline';

class FloantaPermissionGuide extends StatefulWidget {
  const FloantaPermissionGuide({
    Key? key,
    required this.inputGranted,
    required this.screenCaptureGranted,
    required this.checkOverlay,
    required this.onOpenAccessibility,
    required this.onOpenScreenCapture,
    required this.onOpenOverlay,
  }) : super(key: key);

  final bool inputGranted;
  final bool screenCaptureGranted;
  final Future<bool> Function() checkOverlay;
  final VoidCallback onOpenAccessibility;
  final VoidCallback onOpenScreenCapture;
  final VoidCallback onOpenOverlay;

  @override
  State<FloantaPermissionGuide> createState() => _FloantaPermissionGuideState();
}

class _FloantaPermissionGuideState extends State<FloantaPermissionGuide>
    with WidgetsBindingObserver {
  bool? _overlayGranted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOverlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOverlay();
    }
  }

  Future<void> _refreshOverlay() async {
    final granted = await widget.checkOverlay();
    if (mounted) {
      setState(() => _overlayGranted = granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final el = floantaDeviceGreek();
    final steps = <_Step>[
      _Step(
        title: el ? '1. Προσβασιμότητα' : '1. Accessibility',
        detail: el
            ? 'Άγγιγμα και πληκτρολόγιο μόνο μέσα σε συνεδρία που εγκρίνετε. Χωρίς αυτή, η προβολή παραμένει δυνατή.'
            : 'Touch and keyboard only inside a session you authorized. Without it, view-only still works.',
        granted: widget.inputGranted,
        onOpen: widget.onOpenAccessibility,
      ),
      _Step(
        title: el ? '2. Καταγραφή οθόνης' : '2. Screen capture',
        detail: el
            ? 'Για να δει ο τεχνικός την οθόνη. Ανοίγει την άδεια καταγραφής του συστήματος.'
            : 'So the technician can see the screen. Opens the system capture prompt.',
        granted: widget.screenCaptureGranted,
        onOpen: widget.onOpenScreenCapture,
      ),
      _Step(
        title: el
            ? '3. Εμφάνιση πάνω από άλλες εφαρμογές'
            : '3. Display over other apps',
        detail: el
            ? 'Για το μικρό παράθυρο της συνεδρίας όσο χρησιμοποιείτε άλλες εφαρμογές.'
            : 'For the small session window while you use other apps.',
        granted: _overlayGranted,
        onOpen: widget.onOpenOverlay,
      ),
    ];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              el ? 'Άδειες συνεδρίας' : 'Session permissions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.merge(const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Text(
              el
                  ? 'Με τη σειρά: προσβασιμότητα, καταγραφή οθόνης, εμφάνιση πάνω από άλλες εφαρμογές.'
                  : 'In order: Accessibility, screen capture, display over other apps.',
            ),
            for (final step in steps) ...[
              const SizedBox(height: 14),
              Text(step.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(step.detail),
              const SizedBox(height: 4),
              Text(
                step.granted == null
                    ? (el ? 'Έλεγχος…' : 'Checking…')
                    : step.granted!
                        ? (el ? 'Ενεργό' : 'Granted')
                        : (el ? 'Λείπει' : 'Missing'),
                style: TextStyle(
                  color: step.granted == true ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: step.onOpen,
                  child: Text(el ? 'Άνοιγμα ρυθμίσεων' : 'Open settings'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step {
  _Step({
    required this.title,
    required this.detail,
    required this.granted,
    required this.onOpen,
  });

  final String title;
  final String detail;
  final bool? granted;
  final VoidCallback onOpen;
}
