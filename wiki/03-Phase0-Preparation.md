# 03 — Phase 0 : Préparation

> Wiki — `iam-ma-integration-lab`

---

## Le principe de cette phase

La Phase 0 est la seule phase du lab qui ne produit aucun script.
Elle produit de la **connaissance structurée** : qui sont les acteurs,
quelles applications existent, quels accès sont critiques, qui doit
être informé et dans quel ordre.

C'est aussi la phase la plus différenciante. La majorité des projets
IAM M&A ratent parce qu'ils l'ignorent et démarrent directement par l'audit.

---

## Les quatre livrables

### 1. Matrice des parties prenantes (`Collect-StakeholderMatrix.md`)

Cartographie les douze personnes clés du projet selon quatre rôles :

- **Décideur** : autorise les actions à fort impact (Go/NoGo Phase 3)
- **Validateur** : confirme la pertinence des données avant action
- **Référent** : source de connaissance métier
- **Informé** : reçoit les communications sans rôle actif

Le fichier contient un template générique (Section A) et l'exemple
CorpA/CorpB complet avec douze personas nommés (Section B), incluant
les **points de vigilance humains** : résistance anticipée de Bastien Couture
sur les dépôts GitLab, anxiété de Julien Faure sur son rôle post-migration.

### 2. Inventaire SaaS (`Collect-SaaSInventory.md`)

Catalogue les huit applications CorpB avec une fiche détaillée pour chacune :
fournisseur, propriétaire fonctionnel, nombre de comptes, MFA, SSO, données
sensibles, statut DSI, DPA, hébergement, niveau de risque.

Le Shadow IT (Dropbox Biz) figure explicitement dans l'inventaire — il a
été détecté via analyse DNS, pas via déclaration DSI.

> Méthodes de collecte recommandées : entretien DSI + questionnaire managers
> + analyse logs proxy/DNS + export facturation IT.
> En lab : catalogue pré-rempli dans le fichier.

### 3. Analyse des risques SaaS (`Audit-SaaSRisk.py`)

Calcule un score de risque composite (0-100) par application sur six critères :
MFA absent, partage de credentials, Shadow IT, données sensibles, DPA manquant,
hébergement hors UE.

```bash
# Mode lab — données CorpB embarquées
python phase0-preparation/Audit-SaaSRisk.py

# Mode réel — fichier CSV fourni
python phase0-preparation/Audit-SaaSRisk.py \
    --input corpb-saas-inventory.csv \
    --output saas-risk-report.csv --verbose
```

Résultats CorpB simulés : 3 applications CRITIQUE (Salesforce, BambooHR, AS400),
3 ÉLEVÉ (SlackConnect, GitLab CE, Dropbox Biz), 2 MODÉRÉ.

### 4. Plan de communication (`OCM-Phase0-Communication.md`)

Quatre messages types à envoyer avant le démarrage de la Phase 1 :
DG-to-DG (J-21), briefing managers (J-14), information collaborateurs (J-10),
briefing IT CorpB (J-7).

---

## Checklist de fin de Phase 0

Avant de passer à la Phase 1, vérifier que :

- [ ] Au moins un Décideur identifié côté CorpA et côté CorpB
- [ ] Un Référent par département CorpB
- [ ] Inventaire SaaS couvrant 100% des applications connues (y compris Shadow IT)
- [ ] Score de risque SaaS produit et partagé avec le RSSI
- [ ] Matrice de criticité accès/fonction remplie
- [ ] Communication DG-to-DG envoyée et accusée de réception
- [ ] Briefing managers planifié

---

## Pourquoi la Phase 0 change tout

Sans Phase 0, l'audit AD de la Phase 1 découvrira 312 comptes, produira
un CSV, et personne ne saura à qui le transmettre pour validation.

Avec la Phase 0, au moment où le CSV de remédiation arrive, chaque manager
sait qu'il va le recevoir, comprend ce qu'on lui demande, et a déjà
eu l'occasion de poser ses questions.

---

*Wiki page 03 — `iam-ma-integration-lab` — IAM-Lab Framework*
