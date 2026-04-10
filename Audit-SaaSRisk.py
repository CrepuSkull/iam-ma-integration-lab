#!/usr/bin/env python3
"""
Audit-SaaSRisk.py
=================
IAM-Lab Framework — iam-ma-integration-lab / phase0-preparation

Objectif :
    Calculer un score de risque composite pour chaque application SaaS inventoriée
    dans le cadre d'un projet d'intégration IAM post M&A.

Entrée  : CSV d'inventaire SaaS (produit par Collect-SaaSInventory.md)
Sortie  : CSV enrichi avec scores + rapport synthétique console

Usage :
    python Audit-SaaSRisk.py --input corpb-saas-inventory.csv --output saas-risk-report.csv
    python Audit-SaaSRisk.py --input corpb-saas-inventory.csv --output saas-risk-report.csv --verbose

Prérequis :
    Python 3.10+
    pip install pandas tabulate colorama

Mapping réglementaire :
    ISO 27001:2022 : A.5.15, A.5.18, A.8.5, A.8.6, A.8.8
    NIS2           : Art. 21 §2(a)(e)(i)
    RGPD/CNIL      : Art. 28, Art. 30, Art. 5(1)(c)

Sécurité :
    Script en LECTURE SEULE — ne modifie aucun système.
    Aucune connexion réseau. Traitement local uniquement.
"""

import argparse
import csv
import sys
import os
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Constantes de scoring
# ---------------------------------------------------------------------------

# Pondération des critères de risque (total = 100 points max)
WEIGHTS = {
    "mfa_absent":              25,   # MFA absent ou partiel — vecteur d'attaque principal
    "credential_sharing":      20,   # Compte partagé — perte de traçabilité individuelle
    "shadow_it":               20,   # Non déclaré DSI — aucune gouvernance
    "sensitive_data":          20,   # Données sensibles hébergées — impact RGPD
    "no_dpa":                  10,   # Pas de DPA signé — non-conformité RGPD Art. 28
    "hosting_outside_eu":       5,   # Hébergement hors UE — transfert sans garanties
}

# Seuils de niveau de risque calculé
RISK_THRESHOLDS = {
    "CRITIQUE": 70,
    "ELEVE":    45,
    "MODERE":   25,
    "FAIBLE":    0,
}

# Colonnes attendues dans le CSV d'entrée
REQUIRED_COLUMNS = [
    "application",
    "categorie",
    "mfa_active",       # Oui / Non / Partiel
    "partage_credentials",  # Oui / Non / Suspicion
    "statut_dsi",       # Declaré / Shadow IT
    "donnees_sensibles",    # Clients / RH / Code source / Finances / Aucune
    "dpa_signe",        # Oui / Non / Inconnu / N/A
    "hebergement",      # UE / Hors UE / Inconnu / On-premises
]

# Données fictives CorpB intégrées (utilisées si pas de CSV fourni)
CORPB_SAMPLE_DATA = [
    {
        "application": "Salesforce",
        "categorie": "CRM",
        "comptes_estimes": 24,
        "mfa_active": "Non",
        "partage_credentials": "Oui",
        "statut_dsi": "Declaré",
        "donnees_sensibles": "Clients",
        "dpa_signe": "Oui",
        "hebergement": "UE",
    },
    {
        "application": "SlackConnect",
        "categorie": "Collaboration",
        "comptes_estimes": 287,
        "mfa_active": "Partiel",
        "partage_credentials": "Non",
        "statut_dsi": "Declaré",
        "donnees_sensibles": "Clients",
        "dpa_signe": "Oui",
        "hebergement": "UE",
    },
    {
        "application": "GitLab CE",
        "categorie": "Dev/SCM",
        "comptes_estimes": 45,
        "mfa_active": "Non",
        "partage_credentials": "Non",
        "statut_dsi": "Declaré",
        "donnees_sensibles": "Code source",
        "dpa_signe": "N/A",
        "hebergement": "On-premises",
    },
    {
        "application": "Notion",
        "categorie": "Knowledge/Doc",
        "comptes_estimes": 156,
        "mfa_active": "Non",
        "partage_credentials": "Non",
        "statut_dsi": "Declaré",
        "donnees_sensibles": "Aucune",
        "dpa_signe": "Oui",
        "hebergement": "UE",
    },
    {
        "application": "BambooHR",
        "categorie": "RH",
        "comptes_estimes": 8,
        "mfa_active": "Non",
        "partage_credentials": "Non",
        "statut_dsi": "Declaré",
        "donnees_sensibles": "RH",
        "dpa_signe": "Oui",
        "hebergement": "UE",
    },
    {
        "application": "AS400",
        "categorie": "ERP Legacy",
        "comptes_estimes": 4,
        "mfa_active": "Non",
        "partage_credentials": "Oui",
        "statut_dsi": "Declaré",
        "donnees_sensibles": "Finances",
        "dpa_signe": "N/A",
        "hebergement": "On-premises",
    },
    {
        "application": "Jira Cloud",
        "categorie": "ITSM",
        "comptes_estimes": 67,
        "mfa_active": "Partiel",
        "partage_credentials": "Non",
        "statut_dsi": "Declaré",
        "donnees_sensibles": "Clients",
        "dpa_signe": "Oui",
        "hebergement": "UE",
    },
    {
        "application": "Dropbox Biz",
        "categorie": "Cloud Storage",
        "comptes_estimes": 34,
        "mfa_active": "Inconnu",
        "partage_credentials": "Suspicion",
        "statut_dsi": "Shadow IT",
        "donnees_sensibles": "Inconnu",
        "dpa_signe": "Non",
        "hebergement": "Hors UE",
    },
]


# ---------------------------------------------------------------------------
# Fonctions de scoring
# ---------------------------------------------------------------------------

def score_mfa(value: str) -> int:
    """Score MFA : absent = plein poids, partiel = demi-poids, inconnu = plein poids."""
    v = value.strip().lower()
    if v in ("non", "no", "false", "inconnu", "unknown"):
        return WEIGHTS["mfa_absent"]
    elif v in ("partiel", "partial"):
        return WEIGHTS["mfa_absent"] // 2
    return 0


def score_credential_sharing(value: str) -> int:
    """Score partage de credentials : oui = plein poids, suspicion = demi-poids."""
    v = value.strip().lower()
    if v in ("oui", "yes", "true"):
        return WEIGHTS["credential_sharing"]
    elif v in ("suspicion",):
        return WEIGHTS["credential_sharing"] // 2
    return 0


def score_shadow_it(value: str) -> int:
    """Score Shadow IT : non déclaré = plein poids."""
    v = value.strip().lower()
    if v in ("shadow it", "shadow_it", "non déclaré", "non declare"):
        return WEIGHTS["shadow_it"]
    return 0


def score_sensitive_data(value: str) -> int:
    """Score données sensibles : toute donnée non-aucune = plein poids, inconnu = demi-poids."""
    v = value.strip().lower()
    if v in ("aucune", "none", ""):
        return 0
    elif v in ("inconnu", "unknown"):
        return WEIGHTS["sensitive_data"] // 2
    return WEIGHTS["sensitive_data"]


def score_dpa(value: str) -> int:
    """Score DPA : absent ou inconnu = plein poids. N/A (on-prem) = 0."""
    v = value.strip().lower()
    if v in ("non", "no"):
        return WEIGHTS["no_dpa"]
    elif v in ("inconnu", "unknown"):
        return WEIGHTS["no_dpa"] // 2
    return 0


def score_hosting(value: str) -> int:
    """Score hébergement : hors UE = plein poids, inconnu = demi-poids."""
    v = value.strip().lower()
    if v in ("hors ue", "hors_ue", "outside eu", "us", "usa"):
        return WEIGHTS["hosting_outside_eu"]
    elif v in ("inconnu", "unknown"):
        return WEIGHTS["hosting_outside_eu"] // 2
    return 0


def compute_risk_level(score: int) -> str:
    """Convertit un score numérique en niveau de risque textuel."""
    for level, threshold in RISK_THRESHOLDS.items():
        if score >= threshold:
            return level
    return "FAIBLE"


def compute_risk_detail(row: dict) -> dict:
    """Calcule le score composite et le détail par critère pour une application."""
    scores = {
        "mfa_absent":         score_mfa(row.get("mfa_active", "Non")),
        "credential_sharing": score_credential_sharing(row.get("partage_credentials", "Non")),
        "shadow_it":          score_shadow_it(row.get("statut_dsi", "")),
        "sensitive_data":     score_sensitive_data(row.get("donnees_sensibles", "")),
        "no_dpa":             score_dpa(row.get("dpa_signe", "Inconnu")),
        "hosting_outside_eu": score_hosting(row.get("hebergement", "Inconnu")),
    }
    total = sum(scores.values())
    level = compute_risk_level(total)

    # Identification des facteurs déclencheurs (critères à score > 0)
    triggers = [k for k, v in scores.items() if v > 0]

    return {
        "score_total": total,
        "niveau_risque": level,
        "detail_scores": scores,
        "facteurs_declencheurs": triggers,
    }


def generate_recommendations(detail: dict, row: dict) -> list[str]:
    """Génère des recommandations contextuelles selon les facteurs de risque."""
    recs = []
    triggers = detail["facteurs_declencheurs"]

    if "mfa_absent" in triggers:
        recs.append("Enforcer MFA avant ou lors de la Phase 3 (migration Entra ID)")
    if "credential_sharing" in triggers:
        recs.append("Créer des comptes nominatifs individuels — supprimer le compte partagé")
    if "shadow_it" in triggers:
        recs.append("Régulariser avec la DSI CorpA ou planifier migration des données avant Phase 3")
    if "sensitive_data" in triggers:
        data_type = row.get("donnees_sensibles", "")
        if "rh" in data_type.lower():
            recs.append("Informer le DPO — données RH soumises à protections renforcées RGPD")
        if "client" in data_type.lower():
            recs.append("Vérifier localisation hébergement et clauses RGPD Art. 28")
        if "code" in data_type.lower():
            recs.append("Auditer les repos pour tokens/secrets exposés avant Phase 1")
    if "no_dpa" in triggers:
        recs.append("Signer un DPA avec le fournisseur ou bloquer l'usage jusqu'à régularisation")
    if "hosting_outside_eu" in triggers:
        recs.append("Documenter les garanties de transfert hors UE (clauses contractuelles types)")

    return recs if recs else ["Aucune action immédiate requise — surveiller en Phase 4"]


# ---------------------------------------------------------------------------
# Lecture / écriture
# ---------------------------------------------------------------------------

def load_csv(filepath: str) -> list[dict]:
    """Charge un CSV d'inventaire SaaS."""
    rows = []
    with open(filepath, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            # Normalisation des clés (minuscules, espaces → underscores)
            normalized = {k.strip().lower().replace(" ", "_"): v.strip() for k, v in row.items()}
            rows.append(normalized)
    return rows


def save_csv(results: list[dict], output_path: str) -> None:
    """Sauvegarde le rapport enrichi en CSV."""
    if not results:
        return

    fieldnames = [
        "application", "categorie", "comptes_estimes",
        "score_total", "niveau_risque",
        "mfa_absent", "credential_sharing", "shadow_it",
        "sensitive_data", "no_dpa", "hosting_outside_eu",
        "facteurs_declencheurs", "recommandations",
        "mfa_active", "partage_credentials", "statut_dsi",
        "donnees_sensibles", "dpa_signe", "hebergement",
    ]

    with open(output_path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter=";", extrasaction="ignore")
        writer.writeheader()
        for row in results:
            writer.writerow(row)


# ---------------------------------------------------------------------------
# Affichage console
# ---------------------------------------------------------------------------

RISK_COLORS = {
    "CRITIQUE": "\033[91m",  # Rouge
    "ELEVE":    "\033[93m",  # Jaune
    "MODERE":   "\033[94m",  # Bleu
    "FAIBLE":   "\033[92m",  # Vert
    "RESET":    "\033[0m",
}


def print_report(results: list[dict], verbose: bool = False) -> None:
    """Affiche le rapport de risques dans la console."""
    print("\n" + "=" * 70)
    print("  IAM-Lab Framework — Audit-SaaSRisk.py")
    print(f"  Rapport généré le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)

    # Tri par score décroissant
    sorted_results = sorted(results, key=lambda x: x["score_total"], reverse=True)

    print(f"\n{'Application':<20} {'Catégorie':<16} {'Score':>6} {'Niveau':<10} {'Comptes':>8}")
    print("-" * 65)

    for r in sorted_results:
        level = r["niveau_risque"]
        color = RISK_COLORS.get(level, "")
        reset = RISK_COLORS["RESET"]
        print(
            f"{r['application']:<20} "
            f"{r['categorie']:<16} "
            f"{r['score_total']:>6} "
            f"{color}{level:<10}{reset} "
            f"{str(r.get('comptes_estimes', '?')):>8}"
        )

    # Synthèse
    print("\n" + "=" * 70)
    print("  SYNTHÈSE")
    print("=" * 70)

    for level in ["CRITIQUE", "ELEVE", "MODERE", "FAIBLE"]:
        count = sum(1 for r in results if r["niveau_risque"] == level)
        color = RISK_COLORS.get(level, "")
        reset = RISK_COLORS["RESET"]
        apps = [r["application"] for r in results if r["niveau_risque"] == level]
        print(f"  {color}{level:<10}{reset} : {count} application(s) — {', '.join(apps) if apps else '—'}")

    # Risques transverses
    print("\n  RISQUES TRANSVERSES")
    print("-" * 65)
    mfa_ko = [r["application"] for r in results if r.get("mfa_absent", 0) > 0]
    shadow = [r["application"] for r in results if r.get("shadow_it", 0) > 0]
    shared = [r["application"] for r in results if r.get("credential_sharing", 0) > 0]
    no_dpa = [r["application"] for r in results if r.get("no_dpa", 0) > 0]

    print(f"  MFA absent/partiel    : {len(mfa_ko)}/8 apps — {', '.join(mfa_ko)}")
    print(f"  Shadow IT             : {len(shadow)}/8 apps — {', '.join(shadow) if shadow else '—'}")
    print(f"  Comptes partagés      : {len(shared)}/8 apps — {', '.join(shared) if shared else '—'}")
    print(f"  DPA manquant          : {len(no_dpa)}/8 apps — {', '.join(no_dpa) if no_dpa else '—'}")

    if verbose:
        print("\n" + "=" * 70)
        print("  DÉTAIL PAR APPLICATION")
        print("=" * 70)
        for r in sorted_results:
            level = r["niveau_risque"]
            color = RISK_COLORS.get(level, "")
            reset = RISK_COLORS["RESET"]
            print(f"\n  [{color}{level}{reset}] {r['application']} — Score : {r['score_total']}/100")
            print(f"  Facteurs : {', '.join(r['facteurs_declencheurs']) if r['facteurs_declencheurs'] else 'Aucun'}")
            print("  Recommandations :")
            for rec in r.get("recommandations_list", []):
                print(f"    → {rec}")

    print("\n" + "=" * 70)
    print("  FIN DU RAPPORT — Mode lecture seule. Aucune modification effectuée.")
    print("=" * 70 + "\n")


# ---------------------------------------------------------------------------
# Point d'entrée principal
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Audit-SaaSRisk.py — Scoring des risques SaaS (IAM-Lab Framework)"
    )
    parser.add_argument(
        "--input", "-i",
        help="Chemin vers le CSV d'inventaire SaaS (optionnel — données CorpB fictives si absent)",
        default=None,
    )
    parser.add_argument(
        "--output", "-o",
        help="Chemin vers le CSV de sortie enrichi",
        default="saas-risk-report.csv",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Affiche le détail des scores et recommandations par application",
    )
    args = parser.parse_args()

    # Chargement des données
    if args.input:
        if not Path(args.input).exists():
            print(f"[ERREUR] Fichier introuvable : {args.input}")
            sys.exit(1)
        print(f"[INFO] Chargement du fichier : {args.input}")
        data = load_csv(args.input)
    else:
        print("[INFO] Aucun fichier fourni — utilisation des données fictives CorpB (lab)")
        data = CORPB_SAMPLE_DATA

    if not data:
        print("[ERREUR] Aucune donnée à traiter.")
        sys.exit(1)

    print(f"[INFO] {len(data)} application(s) chargée(s).")

    # Calcul des scores
    results = []
    for row in data:
        detail = compute_risk_detail(row)
        recs = generate_recommendations(detail, row)

        enriched = dict(row)
        enriched["score_total"] = detail["score_total"]
        enriched["niveau_risque"] = detail["niveau_risque"]
        enriched["facteurs_declencheurs"] = " | ".join(detail["facteurs_declencheurs"])
        enriched["recommandations"] = " | ".join(recs)
        enriched["recommandations_list"] = recs  # Pour l'affichage verbose (non exporté)

        # Scores détaillés par critère
        for criterion, score in detail["detail_scores"].items():
            enriched[criterion] = score

        results.append(enriched)

    # Sauvegarde CSV
    save_csv(results, args.output)
    print(f"[INFO] Rapport CSV sauvegardé : {args.output}")

    # Affichage console
    print_report(results, verbose=args.verbose)


if __name__ == "__main__":
    main()
