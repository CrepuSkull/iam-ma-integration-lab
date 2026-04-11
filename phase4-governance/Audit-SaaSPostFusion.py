#!/usr/bin/env python3
"""
Audit-SaaSPostFusion.py
=======================
IAM-Lab Framework — iam-ma-integration-lab / phase4-governance

Objectif :
    Gouvernance des comptes SaaS CorpB post-intégration.
    Croise le dataset SaaS CorpB (Phase 0) avec l'état de la migration AD
    pour identifier les comptes SaaS qui doivent être :
      - DESACTIVER   : utilisateur AD désactivé ou non migré
      - TRANSFERER   : compte transféré au propriétaire CorpA
      - REGULARISER  : compte Shadow IT ou email perso à normaliser
      - CONSERVER    : compte légitime, utilisateur migré actif

Usage :
    python Audit-SaaSPostFusion.py
    python Audit-SaaSPostFusion.py --saas ../seed/corpb-saas-accounts.csv \
                                   --users ../seed/corpb-users.csv \
                                   --output ../reports/

Prérequis :
    Python 3.10+
    pip install pandas tabulate colorama --break-system-packages

Mapping réglementaire :
    ISO 27001:2022 : A.5.15, A.5.18
    NIS2           : Art. 21 §2(i)
    RGPD/CNIL      : Art. 28, Art. 5(1)(c)

Mode : LECTURE SEULE — aucune action sur les applications SaaS.
"""

import argparse
import csv
import sys
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Comptes SaaS dont l'action est critique indépendamment du statut AD
CRITICAL_ACCOUNTS = {
    "sf-admin@corpb.com":   "Compte Admin Salesforce partagé — transfert propriété CorpA requis",
    "QSECOFR":              "Profil sécurité AS400 — plan de migration ERP requis",
    "CORPB_PROD":           "Compte générique AS400 — documenter ou résilier",
    "token-api-bc":         "Token GitLab exposé — révocation confirmée ?",
    "token-api-deploy":     "Token CI/CD exposé — révocation confirmée ?",
    "token-api-legacy":     "Token legacy — révocation confirmée ?",
}

# Applications prioritaires pour la gouvernance post-fusion
APP_PRIORITY = {
    "Salesforce":   "HAUTE",
    "BambooHR":     "HAUTE",
    "AS400":        "HAUTE",
    "GitLab CE":    "HAUTE",
    "SlackConnect": "MOYENNE",
    "Jira Cloud":   "MOYENNE",
    "Notion":       "BASSE",
    "Dropbox Biz":  "BASSE",
}

# ---------------------------------------------------------------------------
# Chargement
# ---------------------------------------------------------------------------

def load_csv(path: str) -> list[dict]:
    with open(path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f, delimiter=";")
        return [row for row in reader]


def load_sample_data():
    """Retourne des données fictives minimales si aucun fichier fourni."""
    saas = [
        {"UID_SaaS":"SAAS0001","Application":"Salesforce","Login_SaaS":"sf-admin@corpb.com",
         "EmailAD":"","Department_AD":"Commercial","IsOrphan":"NON","IsSpecialAccount":"OUI",
         "RiskFlag":"COMPTE_PARTAGE","ShadowIT":"NON","MFA_Active":"NON"},
        {"UID_SaaS":"SAAS0002","Application":"Salesforce","Login_SaaS":"n.perrin@corpb.local",
         "EmailAD":"n.perrin@corpb.local","Department_AD":"Commercial","IsOrphan":"NON",
         "IsSpecialAccount":"NON","RiskFlag":"","ShadowIT":"NON","MFA_Active":"NON"},
        {"UID_SaaS":"SAAS0010","Application":"BambooHR","Login_SaaS":"a.leconte@corpb.local",
         "EmailAD":"a.leconte@corpb.local","Department_AD":"RH","IsOrphan":"NON",
         "IsSpecialAccount":"NON","RiskFlag":"","ShadowIT":"NON","MFA_Active":"NON"},
        {"UID_SaaS":"SAAS0020","Application":"GitLab CE","Login_SaaS":"token-api-bc",
         "EmailAD":"","Department_AD":"Technique","IsOrphan":"NON","IsSpecialAccount":"OUI",
         "RiskFlag":"TOKEN_EXPOSE","ShadowIT":"NON","MFA_Active":"NON"},
        {"UID_SaaS":"SAAS0030","Application":"Dropbox Biz","Login_SaaS":"p.esteves@corpb.local",
         "EmailAD":"p.esteves@corpb.local","Department_AD":"Prestataires","IsOrphan":"NON",
         "IsSpecialAccount":"NON","RiskFlag":"SHADOW_IT","ShadowIT":"OUI","MFA_Active":"NON"},
        {"UID_SaaS":"SAAS0040","Application":"Notion","Login_SaaS":"j.dupont@gmail.com",
         "EmailAD":"","Department_AD":"","IsOrphan":"NON","IsSpecialAccount":"NON",
         "RiskFlag":"EMAIL_PERSO","ShadowIT":"NON","MFA_Active":"NON"},
        {"UID_SaaS":"SAAS0050","Application":"SlackConnect","Login_SaaS":"x.ancien@corpb.local",
         "EmailAD":"x.ancien@corpb.local","Department_AD":"Archived","IsOrphan":"OUI",
         "IsSpecialAccount":"NON","RiskFlag":"","ShadowIT":"NON","MFA_Active":"NON"},
    ]
    users = [
        {"sAMAccountName":"n.perrin","Enabled":"TRUE","IsStale":"FALSE","Department":"Commercial"},
        {"sAMAccountName":"a.leconte","Enabled":"TRUE","IsStale":"FALSE","Department":"RH"},
        {"sAMAccountName":"p.esteves","Enabled":"TRUE","IsStale":"FALSE","Department":"Prestataires"},
        {"sAMAccountName":"x.ancien","Enabled":"FALSE","IsStale":"TRUE","Department":"Archived"},
    ]
    return saas, users


# ---------------------------------------------------------------------------
# Logique de gouvernance
# ---------------------------------------------------------------------------

def determine_action(saas_row: dict, ad_user: dict | None) -> tuple[str, str, str]:
    """
    Retourne (action, justification, priorité).
    """
    login      = saas_row.get("Login_SaaS", "")
    is_orphan  = saas_row.get("IsOrphan", "NON") == "OUI"
    shadow_it  = saas_row.get("ShadowIT", "NON") == "OUI"
    risk_flag  = saas_row.get("RiskFlag", "")
    email_ad   = saas_row.get("EmailAD", "")
    app        = saas_row.get("Application", "")
    is_special = saas_row.get("IsSpecialAccount", "NON") == "OUI"

    # Cas spéciaux documentés
    if login in CRITICAL_ACCOUNTS:
        return "TRAITEMENT_SPECIAL", CRITICAL_ACCOUNTS[login], "HAUTE"

    # Token exposé
    if "TOKEN_EXPOSE" in risk_flag:
        return "REVOQUER_URGENT", "Token d'API exposé — révocation immédiate requise", "HAUTE"

    # Shadow IT
    if shadow_it:
        return "REGULARISER", "Application non déclarée DSI — régulariser ou migrer les données", "MOYENNE"

    # Email personnel
    if "EMAIL_PERSO" in risk_flag:
        return "REGULARISER", "Compte avec email personnel — hors périmètre AD, impossible à gouverner centralement", "MOYENNE"

    # Pas de correspondance AD
    if not email_ad or not ad_user:
        if is_orphan:
            return "DESACTIVER", "Compte orphelin SaaS sans correspondance AD — utilisateur inconnu", "HAUTE"
        return "INVESTIGUER", "Aucun compte AD correspondant trouvé — vérifier manuellement", "MOYENNE"

    # Correspondance AD trouvée
    ad_enabled = ad_user.get("Enabled", "FALSE") == "TRUE"
    ad_stale   = ad_user.get("IsStale", "FALSE") == "TRUE"

    if not ad_enabled or ad_stale:
        return "DESACTIVER", f"Utilisateur AD désactivé/obsolète ({ad_user.get('sAMAccountName','?')}) — accès SaaS à révoquer", "HAUTE"

    if ad_user.get("Department", "") == "Archived":
        return "DESACTIVER", "Département AD : Archived — collaborateur parti", "HAUTE"

    # Compte actif, AD correspondant actif
    return "CONSERVER", f"Utilisateur AD actif ({ad_user.get('sAMAccountName','?')}) — accès SaaS légitime", "BASSE"


# ---------------------------------------------------------------------------
# Rapport
# ---------------------------------------------------------------------------

def print_report(results: list[dict]) -> None:
    print()
    print("=" * 70)
    print("  IAM-Lab Framework — Audit-SaaSPostFusion.py")
    print(f"  Rapport généré le {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)

    by_action = defaultdict(list)
    for r in results:
        by_action[r["ActionGouvernance"]].append(r)

    action_order = ["REVOQUER_URGENT","TRAITEMENT_SPECIAL","DESACTIVER",
                    "REGULARISER","INVESTIGUER","CONSERVER"]

    colors = {
        "REVOQUER_URGENT":    "\033[91m",
        "TRAITEMENT_SPECIAL": "\033[91m",
        "DESACTIVER":         "\033[93m",
        "REGULARISER":        "\033[94m",
        "INVESTIGUER":        "\033[95m",
        "CONSERVER":          "\033[92m",
        "RESET":              "\033[0m",
    }

    print()
    print(f"  {'Application':<18} {'Login SaaS':<30} {'Action':<22} {'Priorité'}")
    print("-" * 90)

    for action in action_order:
        if action not in by_action:
            continue
        for r in sorted(by_action[action], key=lambda x: x["Application"]):
            color = colors.get(action, "")
            reset = colors["RESET"]
            login = r["Login_SaaS"][:28] + ".." if len(r["Login_SaaS"]) > 30 else r["Login_SaaS"]
            print(f"  {r['Application']:<18} {login:<30} {color}{action:<22}{reset} {r['PrioriteAction']}")

    print()
    print("=" * 70)
    print("  SYNTHÈSE PAR ACTION")
    print("=" * 70)
    for action in action_order:
        if action in by_action:
            count = len(by_action[action])
            color = colors.get(action, "")
            reset = colors["RESET"]
            apps  = set(r["Application"] for r in by_action[action])
            print(f"  {color}{action:<22}{reset} : {count:>4} compte(s) — apps : {', '.join(sorted(apps))}")

    print()
    print("  SYNTHÈSE PAR APPLICATION")
    print("-" * 70)
    by_app = defaultdict(list)
    for r in results:
        by_app[r["Application"]].append(r)

    for app in sorted(by_app.keys()):
        prio   = APP_PRIORITY.get(app, "BASSE")
        counts = defaultdict(int)
        for r in by_app[app]:
            counts[r["ActionGouvernance"]] += 1
        summary = ", ".join(f"{a}:{n}" for a,n in counts.items() if a != "CONSERVER")
        conserved = counts.get("CONSERVER", 0)
        print(f"  {app:<18} [{prio}]  Actifs: {conserved}  Actions: {summary or '—'}")

    print()
    print("=" * 70)
    print("  FIN DU RAPPORT — LECTURE SEULE. Aucune modification effectuée.")
    print("=" * 70)
    print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Audit-SaaSPostFusion.py — Gouvernance SaaS post-intégration M&A"
    )
    parser.add_argument("--saas",   default=None, help="CSV comptes SaaS CorpB")
    parser.add_argument("--users",  default=None, help="CSV comptes AD CorpB")
    parser.add_argument("--output", default="../reports/", help="Répertoire de sortie")
    args = parser.parse_args()

    output_path = Path(args.output)
    output_path.mkdir(parents=True, exist_ok=True)
    timestamp   = datetime.now().strftime("%Y%m%d-%H%M%S")
    output_file = output_path / f"phase4-saas-postfusion_{timestamp}.csv"

    # Chargement
    if args.saas and args.users:
        print(f"[INFO] Chargement SaaS  : {args.saas}")
        print(f"[INFO] Chargement Users : {args.users}")
        saas_rows = load_csv(args.saas)
        user_rows = load_csv(args.users)
    else:
        print("[INFO] Aucun fichier fourni — données fictives CorpB (lab)")
        saas_rows, user_rows = load_sample_data()

    # Index AD par email
    ad_index = {}
    for u in user_rows:
        email = u.get("EmailAddress", u.get("UserPrincipalName", "")).lower().strip()
        sam   = u.get("sAMAccountName", "").lower().strip()
        if email:
            ad_index[email] = u
        if sam:
            ad_index[sam]   = u

    print(f"[INFO] {len(saas_rows)} comptes SaaS / {len(user_rows)} comptes AD chargés")

    # Traitement
    results = []
    for row in saas_rows:
        login    = row.get("Login_SaaS", "").lower().strip()
        email_ad = row.get("EmailAD", "").lower().strip()

        # Chercher la correspondance AD
        ad_user = ad_index.get(email_ad) or ad_index.get(login.split("@")[0])

        action, justification, priority = determine_action(row, ad_user)

        results.append({
            "UID_SaaS":          row.get("UID_SaaS", ""),
            "Application":       row.get("Application", ""),
            "Login_SaaS":        row.get("Login_SaaS", ""),
            "EmailAD":           row.get("EmailAD", ""),
            "Department_AD":     row.get("Department_AD", ""),
            "IsOrphan":          row.get("IsOrphan", ""),
            "IsSpecialAccount":  row.get("IsSpecialAccount", ""),
            "ShadowIT":          row.get("ShadowIT", ""),
            "RiskFlag":          row.get("RiskFlag", ""),
            "MFA_Active":        row.get("MFA_Active", ""),
            "AD_Enabled":        ad_user.get("Enabled", "—") if ad_user else "—",
            "AD_IsStale":        ad_user.get("IsStale", "—") if ad_user else "—",
            "ActionGouvernance": action,
            "Justification":     justification,
            "PrioriteAction":    priority,
            "PrioritéApp":       APP_PRIORITY.get(row.get("Application",""), "BASSE"),
            "AuditDate":         datetime.now().strftime("%Y-%m-%d"),
        })

    # Export CSV
    if results:
        fieldnames = list(results[0].keys())
        with open(output_file, "w", newline="", encoding="utf-8-sig") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter=";")
            writer.writeheader()
            writer.writerows(results)
        print(f"[OK] Rapport exporté : {output_file}")

    print_report(results)


if __name__ == "__main__":
    main()
