# 🗓️ OCM-Phase3-MigrationGuide.md — Guide utilisateur J-Day

> `iam-ma-integration-lab` / ocm
> Livrable OCM associé à la Phase 3 — Migration
> À envoyer aux collaborateurs CorpB J-3 avant la date de bascule
> Langue : Français | Destinataires : tous les collaborateurs CorpB

---

## Section A — Template générique

> Instructions : compléter les placeholders `[À COMPLÉTER]`.
> Ce document est écrit pour un collaborateur non-technicien.
> Règle de rédaction : une action = une phrase. Pas de jargon.

### A.1 — Objet du guide

Ce guide répond à une seule question : **que doit faire un collaborateur
de [Entreprise cible] le jour où ses accès informatiques changent ?**

Il couvre trois moments :
- Avant J-Day : se préparer
- J-Day : se connecter pour la première fois
- Après J-Day : que faire si ça ne marche pas

### A.2 — Template email d'envoi (J-3)

```
Objet : [Action requise le [date J-Day]] Vos nouveaux accès informatiques

Chers collègues,

Dans [X] jours, le [date J-Day], vos accès informatiques basculeront
vers les systèmes de [Entreprise absorbante].

Ce que ça change concrètement :
→ Votre nouvel identifiant sera : [prenom.nom]@[domaine cible]
→ Vous devrez configurer une double authentification (MFA) à votre
  première connexion
→ Tous vos outils habituels ([liste outils] ) restent accessibles

Vous trouverez ci-dessous un guide pas-à-pas pour la première connexion.

En cas de problème le jour J : [email support] ou [numéro téléphone]

Bonne journée,
[Signature]
```

### A.3 — Template guide pas-à-pas

```
────────────────────────────────────────────────────
  GUIDE DE PREMIÈRE CONNEXION — [Date J-Day]
────────────────────────────────────────────────────

ÉTAPE 1 — Ouvrir votre navigateur
Aller sur : https://portal.office.com
(ou https://myapps.microsoft.com)

ÉTAPE 2 — Saisir votre nouvel identifiant
Votre identifiant : [prenom.nom]@[domaine cible]
Exemple : jean.dupont@[domaine cible]

ÉTAPE 3 — Saisir votre mot de passe temporaire
Vous avez reçu votre mot de passe temporaire par [canal].
Saisissez-le. Vous serez immédiatement invité à le changer.

ÉTAPE 4 — Choisir votre nouveau mot de passe
Votre nouveau mot de passe doit :
✓ Contenir au moins 12 caractères
✓ Inclure des majuscules, des chiffres et un caractère spécial
✗ Ne pas être un mot de passe déjà utilisé

ÉTAPE 5 — Configurer la double authentification (MFA)
Vous serez guidé pour configurer Microsoft Authenticator sur votre
téléphone. Cette étape prend environ 3 minutes.

Télécharger l'application avant J-Day : chercher
"Microsoft Authenticator" dans l'App Store ou Google Play.

ÉTAPE 6 — Vérifier vos accès
Vérifiez que vous pouvez accéder à vos outils habituels.
Si un outil manque : contacter [email support]

────────────────────────────────────────────────────
  EN CAS DE PROBLÈME
────────────────────────────────────────────────────
Mot de passe temporaire non reçu → [email support]
Problème MFA                     → [email support]
Outil inaccessible               → [email support]
Urgence                          → [numéro téléphone]
────────────────────────────────────────────────────
```

### A.4 — Template pour les managers (briefing équipe)

```
Objet : Briefing équipe — bascule informatique le [date J-Day]

[Prénom],

Je vous invite à informer votre équipe des points suivants avant [date J-Day] :

1. La bascule a lieu le [date J-Day] à partir de [heure]
2. Chacun devra se reconnecter avec un nouvel identifiant
3. Le guide de première connexion leur a été envoyé
4. Prévoir environ 10-15 minutes pour la première connexion
5. En cas de problème : [email support]

Points d'attention pour votre équipe :
[À COMPLÉTER selon les outils critiques du département]

Merci de confirmer que votre équipe est informée.
[Signature]
```

---

## Section B — Exemple CorpA/CorpB

### B.1 — Email d'envoi J-3

**Émetteur** : Sophie Arnaud (DSI CorpA) / Claire Imbert (DG CorpB)
**Destinataires** : tous les collaborateurs CorpB (287 personnes)
**Date d'envoi** : J-3 (mardi pour un vendredi J-Day)

---

**Objet : [Action requise vendredi] Vos nouveaux accès informatiques CorpA**

Chers collègues,

Vendredi prochain, vos accès informatiques basculeront vers les systèmes de CorpA. Ce changement concerne l'ensemble des collaborateurs de CorpB.

**Ce que ça change concrètement :**
- Votre nouvel identifiant sera : `prenom.nom@corpa.fr`
  (exemple : `jean.dupont@corpa.fr`)
- Vous devrez configurer une application sur votre téléphone (Microsoft Authenticator) pour sécuriser votre compte — cela prend 3 minutes
- Slack, Salesforce, Jira, Notion et BambooHR restent accessibles — vous vous y connecterez avec votre nouvel identifiant

**Ce qui ne change pas :**
- Vos fichiers et documents
- Vos outils quotidiens
- Votre AS400 (traitement séparé — votre responsable vous informera)

**Avant vendredi, une seule action recommandée :**
Télécharger l'application **Microsoft Authenticator** sur votre téléphone (App Store ou Google Play, c'est gratuit).

Le guide complet de première connexion est ci-dessous.

En cas de problème vendredi : **it-helpdesk@corpa.fr** ou **06 XX XX XX XX** (disponible de 8h à 18h)

Sophie Arnaud & Claire Imbert

---

### B.2 — Guide de première connexion

```
════════════════════════════════════════════════════
  GUIDE DE PREMIÈRE CONNEXION
  Date : vendredi [date J-Day] à partir de 8h00
  Support : it-helpdesk@corpa.fr | 06 XX XX XX XX
════════════════════════════════════════════════════

ÉTAPE 1 — Ouvrir votre navigateur
Aller sur : https://myapps.microsoft.com

ÉTAPE 2 — Saisir votre nouvel identifiant
Format : prenom.nom@corpa.fr
Exemple : nadege.perrin@corpa.fr

Si vous avez un prénom composé ou un nom avec accent :
contacter it-helpdesk@corpa.fr pour confirmer votre identifiant.

ÉTAPE 3 — Mot de passe temporaire
Vous recevrez votre mot de passe temporaire par SMS
le jeudi soir avant la bascule.

Saisissez-le. Le système vous demandera immédiatement
de le changer.

ÉTAPE 4 — Choisir votre nouveau mot de passe
Votre nouveau mot de passe doit :
✓ Faire au moins 12 caractères
✓ Contenir au moins 1 majuscule
✓ Contenir au moins 1 chiffre
✓ Contenir au moins 1 caractère spécial (! @ # $ ...)
✗ Ne pas contenir votre prénom ou nom

ÉTAPE 5 — Configurer Microsoft Authenticator (MFA)
Cette étape est obligatoire. Elle prend 3 minutes.

1. Ouvrir Microsoft Authenticator sur votre téléphone
   (si non installé : App Store ou Google Play → "Microsoft Authenticator")
2. Dans l'application : + → Compte professionnel ou scolaire → Scanner le QR code
3. Scanner le QR code affiché sur votre écran
4. Saisir le code à 6 chiffres affiché dans l'application

Après cette étape, votre compte est sécurisé.

ÉTAPE 6 — Vérifier vos accès
Depuis https://myapps.microsoft.com, vérifier que vous voyez
vos applications habituelles (Outlook, Teams, Slack...).

Si une application manque : it-helpdesk@corpa.fr

════════════════════════════════════════════════════
  AS400 (équipe Comptabilité)
════════════════════════════════════════════════════
L'AS400 ne change pas vendredi. Votre responsable
vous informera séparément des modalités de transition.
════════════════════════════════════════════════════

════════════════════════════════════════════════════
  EN CAS DE PROBLÈME
════════════════════════════════════════════════════
Mot de passe temporaire non reçu  → it-helpdesk@corpa.fr
Code MFA qui ne fonctionne pas    → it-helpdesk@corpa.fr
Application inaccessible          → it-helpdesk@corpa.fr
Urgence (bloqué, travail arrêté)  → 06 XX XX XX XX
════════════════════════════════════════════════════
```

---

### B.3 — Email briefing managers (J-4)

**Émetteur** : Sophie Arnaud
**Destinataires** : Nadège Perrin, Bastien Couture, Amandine Leconte, Paulo Esteves, Thierry Vogt

---

**Objet : Briefing manager — bascule informatique vendredi**

Nadège, Bastien, Amandine, Paulo, Thierry,

La bascule a lieu **vendredi à partir de 8h00**. Voici ce que je vous demande de relayer à vos équipes avant jeudi soir.

**Ce qu'ils vont recevoir :**
- Jeudi soir : SMS avec leur mot de passe temporaire
- Mardi (aujourd'hui) : l'email avec le guide de première connexion

**Ce que vous pouvez leur dire :**
1. Ça prend 10 à 15 minutes la première fois
2. Télécharger Microsoft Authenticator avant vendredi (App Store / Play Store)
3. En cas de problème : it-helpdesk@corpa.fr ou le 06 pendant toute la journée

**Points spécifiques par équipe :**

*Commercial (Nadège)* : Salesforce sera accessible avec le nouvel identifiant. Le compte Admin partagé a été remplacé — chaque commercial a son propre compte. Si quelqu'un n'arrive pas à se connecter à Salesforce, signaler immédiatement.

*Technique (Bastien)* : GitLab CE reste accessible en transition. La migration vers GitLab CorpA est prévue en Phase 4. Jira : accès via le nouvel identifiant dès vendredi.

*RH (Amandine)* : BambooHR : le MFA sera activé vendredi — vos collaborateurs RH suivront le même guide. Les données RH sont inchangées.

*Prestataires (Paulo)* : les prestataires externes ont leur propre procédure — je vous contacte séparément.

*IT (Thierry)* : Julien et toi êtes en astreinte vendredi de 8h à 12h pour accompagner les cas complexes en local.

Merci de confirmer réception.
Sophie

---

### B.4 — Communication J+1 (confirmation post-bascule)

**Objet : ✓ Migration terminée — vos accès sont opérationnels**

Chers collègues,

La bascule informatique est terminée. Les 263 comptes CorpB ont été activés dans l'environnement CorpA.

**Si vous avez réussi à vous connecter :** aucune action requise.

**Si vous rencontrez encore un problème d'accès :** contacter it-helpdesk@corpa.fr — nous traitons les cas résiduels en priorité aujourd'hui.

**Rappel :** votre identifiant est désormais `prenom.nom@corpa.fr` pour tous vos accès professionnels.

Merci pour votre patience et votre coopération.

Sophie Arnaud & l'équipe IT CorpA

---

### B.5 — Suivi de diffusion Phase 3 OCM

| Communication | Envoyée | Canal | Retours reçus |
|---|---|---|---|
| Email J-3 (tous collaborateurs) | [ ] | Email CorpB | — |
| Briefing managers J-4 | [ ] | Email | — |
| SMS mots de passe temporaires J-1 | [ ] | SMS | — |
| Confirmation J+1 | [ ] | Email | — |

**Indicateurs J-Day :**

| Indicateur | Cible | Résultat |
|---|---|---|
| Connexions réussies J-Day (8h-12h) | > 80% | — |
| Tickets support J-Day | < 15 | — |
| MFA configuré J+5 | > 90% | — |
| Comptes non connectés J+7 | < 5 | — |

---

*OCM Phase 3 — Guide utilisateur J-Day — `iam-ma-integration-lab` — IAM-Lab Framework*
