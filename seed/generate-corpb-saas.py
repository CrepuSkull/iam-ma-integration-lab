#!/usr/bin/env python3
"""
generate-corpb-saas.py
======================
Générateur du dataset fictif SaaS CorpB — 625 comptes applicatifs
IAM-Lab Framework — iam-ma-integration-lab / seed

Usage :
    python generate-corpb-saas.py
    Produit : corpb-saas-accounts.csv
"""

import csv
import random
from datetime import datetime, timedelta

random.seed(42)

# ---------------------------------------------------------------------------
# Référentiel SaaS CorpB
# ---------------------------------------------------------------------------

APPS = {
    "Salesforce": {
        "categorie": "CRM",
        "quota": 24,
        "roles": ["Standard User", "Manager", "Admin", "Read Only"],
        "role_weights": [70, 20, 5, 5],
        "mfa_policy": "absent",
        "sso": False,
        "comptes_speciaux": [
            {"sam": "sf-admin@corpb.com", "role": "Admin", "shared": True,
             "description": "Compte Admin partagé — Nadège Perrin + ex-collaborateur",
             "stale_risk": True},
        ],
    },
    "SlackConnect": {
        "categorie": "Collaboration",
        "quota": 287,
        "roles": ["Member", "Admin", "Workspace Admin", "Guest"],
        "role_weights": [80, 5, 5, 10],
        "mfa_policy": "partial",
        "sso": False,
    },
    "GitLab CE": {
        "categorie": "Dev/SCM",
        "quota": 45,
        "roles": ["Developer", "Maintainer", "Owner", "Reporter"],
        "role_weights": [65, 20, 5, 10],
        "mfa_policy": "absent",
        "sso": False,
        "comptes_speciaux": [
            {"sam": "token-api-bc", "role": "Developer", "shared": False,
             "description": "Token personnel exposé dans commit #a3f2c1 — repo infra-scripts",
             "stale_risk": False},
            {"sam": "token-api-deploy", "role": "Maintainer", "shared": False,
             "description": "Token CI/CD en clair dans .env committé",
             "stale_risk": False},
            {"sam": "token-api-legacy", "role": "Reporter", "shared": False,
             "description": "Token ancien projet — jamais révoqué",
             "stale_risk": True},
        ],
    },
    "Notion": {
        "categorie": "Knowledge/Doc",
        "quota": 156,
        "roles": ["Full Access", "Edit", "Comment", "View"],
        "role_weights": [30, 40, 20, 10],
        "mfa_policy": "absent",
        "sso": False,
    },
    "BambooHR": {
        "categorie": "RH",
        "quota": 8,
        "roles": ["Admin", "HR Manager", "Manager Self-Service", "Employee"],
        "role_weights": [12, 25, 38, 25],
        "mfa_policy": "absent",
        "sso": False,
    },
    "AS400": {
        "categorie": "ERP Legacy",
        "quota": 4,
        "roles": ["QSECOFR", "USERADM", "PGMR", "USER"],
        "role_weights": [25, 25, 25, 25],
        "mfa_policy": "impossible",
        "sso": False,
        "comptes_speciaux": [
            {"sam": "QSECOFR", "role": "QSECOFR", "shared": True,
             "description": "Profil sécurité IBM i — mot de passe générique jamais changé",
             "stale_risk": False},
            {"sam": "CORPB_PROD", "role": "USERADM", "shared": True,
             "description": "Compte générique production — partagé entre 3 utilisateurs",
             "stale_risk": False},
        ],
    },
    "Jira Cloud": {
        "categorie": "ITSM",
        "quota": 67,
        "roles": ["Agent", "Project Lead", "Developer", "Client Portal"],
        "role_weights": [50, 10, 30, 10],
        "mfa_policy": "partial",
        "sso": False,
    },
    "Dropbox Biz": {
        "categorie": "Cloud Storage",
        "quota": 34,
        "roles": ["Member", "Admin", "Viewer"],
        "role_weights": [75, 10, 15],
        "mfa_policy": "unknown",
        "sso": False,
        "shadow_it": True,
    },
}

# Correspondance OU → apps probables (pour le champ Department simulé)
OU_APP_AFFINITY = {
    "Direction":    ["Salesforce", "SlackConnect", "Notion", "BambooHR"],
    "Commercial":   ["Salesforce", "SlackConnect", "Notion", "Jira Cloud"],
    "Technique":    ["GitLab CE", "Jira Cloud", "SlackConnect", "Notion"],
    "RH":           ["BambooHR", "SlackConnect", "Notion"],
    "Prestataires": ["Jira Cloud", "Dropbox Biz", "SlackConnect"],
    "ServiceCompt": ["AS400", "Notion"],
    "Archived":     [],
}

# Prénoms/Noms réutilisés du dataset AD (cohérence)
NOMS_POOL = [
    ("Thomas","Moulin"), ("Laurent","Henry"), ("Christophe","Vincent"), ("Margot","Martin"),
    ("Sophie","Arnaud"), ("Julie","Roux"), ("Nicolas","Bernard"), ("Pierre","Dubois"),
    ("Julien","Faure"), ("Antoine","Moreau"), ("Maxime","Lefebvre"), ("Guillaume","Simon"),
    ("Nadège","Perrin"), ("Bastien","Couture"), ("Amandine","Leconte"), ("Paulo","Esteves"),
    ("Thierry","Vogt"), ("Claire","Imbert"), ("Marc","Deschamps"), ("Inès","Moulin"),
    ("Romain","Laurent"), ("Baptiste","Richard"), ("Sébastien","Dupont"), ("Florian","Girard"),
    ("Mathieu","Bonnet"), ("Aurélien","Lambert"), ("Damien","Fontaine"), ("Kevin","Rousseau"),
    ("Jonathan","Blanc"), ("Céline","Garnier"), ("Nathalie","Chevalier"), ("Sandrine","François"),
    ("Valérie","Legrand"), ("Aurélie","Gauthier"), ("Pauline","Garcia"), ("Anaïs","Perrot"),
    ("Laetitia","Caron"), ("Clémence","Renard"), ("Charlotte","Schmitt"), ("Manon","Colin"),
    ("Alice","Bourgeois"), ("Léa","Lemaire"), ("Lucie","Masson"), ("Margot","Henry"),
    ("Élise","Robin"), ("Sarah","Noel"), ("Marion","Mallet"), ("Adèle","Leclercq"),
    ("Yann","Brun"), ("Cédric","Picard"),
]

def weighted_choice(options, weights):
    total = sum(weights)
    r = random.uniform(0, total)
    cumulative = 0
    for opt, w in zip(options, weights):
        cumulative += w
        if r <= cumulative:
            return opt
    return options[-1]

def random_date_saas(stale=False):
    if stale:
        start = datetime(2020, 1, 1)
        end = datetime(2022, 6, 30)
    else:
        start = datetime(2022, 7, 1)
        end = datetime(2024, 12, 31)
    delta = end - start
    return (start + timedelta(days=random.randint(0, delta.days))).strftime("%Y-%m-%d")

def generate_saas_accounts():
    rows = []
    uid = 1

    for app_name, cfg in APPS.items():
        quota = cfg["quota"]
        roles = cfg["roles"]
        weights = cfg["role_weights"]
        mfa = cfg["mfa_policy"]
        sso = cfg["sso"]
        shadow = cfg.get("shadow_it", False)
        speciaux = cfg.get("comptes_speciaux", [])

        # Comptes spéciaux en premier
        for sp in speciaux:
            stale = sp.get("stale_risk", False)
            row = {
                "UID_SaaS": f"SAAS{uid:04d}",
                "Application": app_name,
                "Categorie": cfg["categorie"],
                "Login_SaaS": sp["sam"],
                "DisplayName": sp["sam"],
                "Role": sp["role"],
                "EmailAD": "",
                "Department_AD": "",
                "ComptePartage": "OUI" if sp.get("shared") else "NON",
                "MFA_Active": "NON" if mfa in ("absent","impossible","unknown") else "OUI",
                "MFA_Policy": mfa,
                "SSO_Configure": "OUI" if sso else "NON",
                "ShadowIT": "OUI" if shadow else "NON",
                "LastLoginDate": random_date_saas(stale=stale),
                "AccountCreated": random_date_saas(stale=True),
                "IsOrphan": "OUI" if stale else "NON",
                "IsSpecialAccount": "OUI",
                "RiskFlag": "TOKEN_EXPOSE" if "token" in sp["sam"].lower() else (
                    "COMPTE_PARTAGE" if sp.get("shared") else ""),
                "Description": sp["description"],
                "Notes": "",
            }
            rows.append(row)
            uid += 1
            quota -= 1  # Décompter du quota

        # Comptes standards
        used_names = []
        for i in range(quota):
            # Choisir un nom du pool (avec remise possible)
            prenom, nom = random.choice(NOMS_POOL)
            sam = f"{prenom[0].lower()}.{nom.lower()}"
            email_ad = f"{sam}@corpb.local"

            # Déterminer le département en fonction de l'app
            dept_candidates = [ou for ou, apps in OU_APP_AFFINITY.items() if app_name in apps]
            department = random.choice(dept_candidates) if dept_candidates else "Direction"

            # Simuler quelques comptes orphelins (~8%)
            is_orphan = (i % 12 == 0)

            # Comptes Notion avec email perso (~8%)
            if app_name == "Notion" and i % 13 == 0:
                providers = ["gmail.com", "hotmail.fr", "outlook.fr", "yahoo.fr"]
                login = f"{sam}@{random.choice(providers)}"
                email_ad = ""  # Hors périmètre AD
                dept = ""
            else:
                login = email_ad
                dept = department

            role = weighted_choice(roles, weights)
            mfa_active = "PARTIEL" if mfa == "partial" else ("NON" if mfa in ("absent","impossible","unknown") else "OUI")

            row = {
                "UID_SaaS": f"SAAS{uid:04d}",
                "Application": app_name,
                "Categorie": cfg["categorie"],
                "Login_SaaS": login,
                "DisplayName": f"{prenom} {nom}",
                "Role": role,
                "EmailAD": email_ad,
                "Department_AD": dept,
                "ComptePartage": "NON",
                "MFA_Active": mfa_active,
                "MFA_Policy": mfa,
                "SSO_Configure": "OUI" if sso else "NON",
                "ShadowIT": "OUI" if shadow else "NON",
                "LastLoginDate": random_date_saas(stale=is_orphan),
                "AccountCreated": random_date_saas(stale=is_orphan),
                "IsOrphan": "OUI" if is_orphan else "NON",
                "IsSpecialAccount": "NON",
                "RiskFlag": "SHADOW_IT" if shadow else ("EMAIL_PERSO" if "@" in login and "corpb" not in login else ""),
                "Description": f"Compte standard {app_name} — {dept or 'hors AD'}",
                "Notes": "",
            }
            rows.append(row)
            uid += 1

    return rows

def main():
    accounts = generate_saas_accounts()

    fieldnames = [
        "UID_SaaS","Application","Categorie","Login_SaaS","DisplayName","Role",
        "EmailAD","Department_AD","ComptePartage","MFA_Active","MFA_Policy",
        "SSO_Configure","ShadowIT","LastLoginDate","AccountCreated",
        "IsOrphan","IsSpecialAccount","RiskFlag","Description","Notes"
    ]

    with open("corpb-saas-accounts.csv", "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter=";")
        writer.writeheader()
        writer.writerows(accounts)

    # Statistiques
    total = len(accounts)
    orphans = sum(1 for a in accounts if a["IsOrphan"] == "OUI")
    shared = sum(1 for a in accounts if a["ComptePartage"] == "OUI")
    shadow = sum(1 for a in accounts if a["ShadowIT"] == "OUI")
    tokens = sum(1 for a in accounts if "TOKEN" in a["RiskFlag"])
    email_perso = sum(1 for a in accounts if "EMAIL_PERSO" in a["RiskFlag"])
    no_mfa = sum(1 for a in accounts if a["MFA_Active"] in ("NON", "PARTIEL"))

    print(f"[OK] corpb-saas-accounts.csv généré — {total} comptes applicatifs")
    print(f"     Comptes orphelins (IsOrphan)   : {orphans}")
    print(f"     Comptes partagés               : {shared}")
    print(f"     Shadow IT                      : {shadow}")
    print(f"     Tokens exposés (RiskFlag)      : {tokens}")
    print(f"     Emails personnels (Notion)     : {email_perso}")
    print(f"     Sans MFA ou MFA partiel        : {no_mfa}")
    print(f"     SSO configuré                  : 0 (aucune app)")

if __name__ == "__main__":
    main()
