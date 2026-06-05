# TODO - Identifier le blocage & corriger les erreurs bloquantes

## Étape 1 — Diagnose compile
- [ ] Corriger l’erreur bloquante dans `frontend_mobile/symberis_mobile/lib/screens/qr_scanner_screen.dart` liée à `MobileScannerController.torchState`.

## Étape 2 — Recompiler
- [ ] Relancer `flutter analyze` / `flutter test` pour vérifier que les erreurs ont disparu.

## Étape 3 — Identifier le vrai blocage runtime (auth)
- [ ] Une fois l’app compilable, retrouver l’endpoint exact qui renvoie 401/403 lors du flow login → dashboard (probablement `utilisateurs/me/` ou refresh JWT).
- [ ] Ajouter/afficher l’erreur dans `DashboardScreen` (ou logger) pour ne plus masquer l’échec réseau.

## Étape 4 — Ajuster si besoin permissions JWT/role
- [ ] Vérifier que le JWT correspond bien à un `Utilisateur` dont `role` vaut `ADMIN/MANAGER/TECHNICIEN`.

