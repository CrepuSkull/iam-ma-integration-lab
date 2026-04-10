#!/usr/bin/env python3
"""
generate-corpb-users.py
=======================
Générateur du dataset fictif CorpB — 312 comptes utilisateurs AD
IAM-Lab Framework — iam-ma-integration-lab / seed

Usage :
    python generate-corpb-users.py
    Produit : corpb-users.csv

Note : ce script est un outil de génération de données de lab.
       Il n'est pas exécuté en contexte réel.
"""

import csv
import random
from datetime import datetime, timedelta

random.seed(42)  # Reproductibilité garantie

# ---------------------------------------------------------------------------
# Référentiel de données fictives
# ---------------------------------------------------------------------------

DOMAINES = ["corpb.local", "legacy.corpb.local"]

OUS = {
    "Direction":    {"domaine": "corpb.local",        "quota": 12,  "legacy": False},
    "Commercial":   {"domaine": "corpb.local",        "quota": 78,  "legacy": False},
    "Technique":    {"domaine": "corpb.local",        "quota": 85,  "legacy": False},
    "RH":           {"domaine": "corpb.local",        "quota": 22,  "legacy": False},
    "Prestataires": {"domaine": "legacy.corpb.local", "quota": 55,  "legacy": True},
    "ServiceCompt": {"domaine": "legacy.corpb.local", "quota": 15,  "legacy": True},
    "Archived":     {"domaine": "legacy.corpb.local", "quota": 45,  "legacy": True},
}
# Total : 312

PRENOMS_M = [
    "Thomas","Nicolas","Pierre","Julien","Antoine","Maxime","Guillaume","Alexandre",
    "Romain","Baptiste","Sébastien","Florian","Mathieu","Aurélien","Damien",
    "Kevin","Jonathan","Christophe","Laurent","Franck","David","Stéphane","Éric",
    "Thierry","Patrick","Bruno","Olivier","Xavier","Yann","Cédric"
]
PRENOMS_F = [
    "Sophie","Marie","Julie","Laura","Camille","Émilie","Isabelle","Céline",
    "Nathalie","Sandrine","Valérie","Aurélie","Pauline","Anaïs","Laetitia",
    "Clémence","Charlotte","Manon","Alice","Léa","Nadège","Amandine","Claire",
    "Inès","Lucie","Margot","Élise","Sarah","Marion","Adèle"
]
NOMS = [
    "Martin","Bernard","Thomas","Petit","Robert","Richard","Durand","Dubois",
    "Moreau","Laurent","Simon","Michel","Lefebvre","Leroy","Roux","David",
    "Bertrand","Morel","Fournier","Girard","Bonnet","Dupont","Lambert","Fontaine",
    "Rousseau","Vincent","Müller","Leconte","Perrin","Vogt","Faure","Couture",
    "Esteves","Arnaud","Benali","Moulin","Imbert","Deschamps","Mercier","Blanc",
    "Garnier","Chevalier","François","Legrand","Gauthier","Garcia","Perrot","Caron",
    "Renard","Schmitt","Colin","Bourgeois","Lemaire","Masson","Henry","Robin",
    "Lemaire","Noel","Mallet","Leclercq","Brun","Picard","Charpentier","Lacroix"
]

GROUPES_PAR_OU = {
    "Direction":    ["GRP_Direction_Managers", "GRP_All_CorpB"],
    "Commercial":   ["GRP_Commercial_Users", "GRP_CRM_Salesforce", "GRP_All_CorpB"],
    "Technique":    ["GRP_Tech_Devs", "GRP_Tech_DevOps", "GRP_GitLab_Users", "GRP_Jira_Agents", "GRP_All_CorpB"],
    "RH":           ["GRP_RH_Users", "GRP_BambooHR_Access", "GRP_All_CorpB"],
    "Prestataires": ["GRP_Prestataires_External", "GRP_Jira_Agents"],
    "ServiceCompt": ["GRP_Finance_Users", "GRP_AS400_Access", "GRP_All_CorpB"],
    "Archived":     [],
}

TITRES_PAR_OU = {
    "Direction":    ["Directeur Général", "Directrice Générale", "DAF", "DRH", "DSI", "Directeur Commercial", "Directrice Marketing"],
    "Commercial":   ["Commercial", "Responsable Commercial", "Account Manager", "Chargé(e) d'affaires", "Business Developer", "Ingénieur Commercial"],
    "Technique":    ["Développeur", "Développeuse", "Lead Dev", "DevOps Engineer", "Architecte", "Analyste", "Chef de Projet Technique"],
    "RH":           ["Chargé(e) RH", "Responsable RH", "Gestionnaire Paie", "Assistante RH", "HRBP"],
    "Prestataires": ["Consultant", "Prestataire", "Développeur Externe", "Analyste Externe"],
    "ServiceCompt": ["Comptable", "Responsable Comptabilité", "Contrôleur de Gestion", "Assistant Comptable"],
    "Archived":     ["Ancien Employé", "Compte Archivé"],
}

def random_date(start_year=2015, end_year=2024):
    start = datetime(start_year, 1, 1)
    end = datetime(end_year, 12, 31)
    delta = end - start
    return (start + timedelta(days=random.randint(0, delta.days))).strftime("%Y-%m-%d")

def is_stale(ou, index):
    """Génère ~40 comptes obsolètes : principalement Archived + quelques autres OUs."""
    if ou == "Archived":
        return True
    # ~5 comptes obsolètes éparpillés hors Archived
    return index % 60 == 0

def is_privileged(ou, index):
    """Génère 6 comptes privilégiés : 3 documentés, 3 non documentés."""
    if ou == "Technique" and index % 28 == 0:
        return True
    if ou == "Direction" and index % 6 == 0:
        return True
    return False

def is_service_account(ou, index):
    """Génère ~15 comptes de service."""
    if ou in ("Technique", "ServiceCompt") and index % 8 == 0:
        return True
    return False

# ---------------------------------------------------------------------------
# Génération des comptes
# ---------------------------------------------------------------------------

def generate_users():
    rows = []
    uid = 1

    for ou, cfg in OUS.items():
        quota = cfg["quota"]
        domaine = cfg["domaine"]

        for i in range(quota):
            # Identité
            genre = random.choice(["M", "F"])
            prenom = random.choice(PRENOMS_M if genre == "M" else PRENOMS_F)
            nom = random.choice(NOMS)

            # Génération du sAMAccountName : p.nom + suffixe si collision simulée
            sam = f"{prenom[0].lower()}.{nom.lower()}"
            if uid % 20 == 0:
                sam = f"{sam}{random.randint(2,9)}"  # Simule quelques doublons de noms

            upn = f"{sam}@{domaine}"

            # Statut du compte
            stale = is_stale(ou, uid)
            privileged = is_privileged(ou, uid)
            service = is_service_account(ou, uid)

            if service:
                sam = f"svc_{ou.lower()}_{uid:03d}"
                upn = f"{sam}@{domaine}"
                prenom = "SVC"
                nom = f"{ou.upper()}_{uid:03d}"

            enabled = "FALSE" if stale else "TRUE"
            last_logon = random_date(2019, 2022) if stale else random_date(2023, 2024)
            created = random_date(2015, 2022) if stale else random_date(2018, 2024)
            pwd_last_set = random_date(2019, 2021) if stale else random_date(2022, 2024)
            pwd_never_expires = "TRUE" if (service or stale) else random.choice(["TRUE", "FALSE"])
            mfa_enabled = "FALSE"  # Aucun MFA sur CorpB AD

            # Groupes
            groupes = GROUPES_PAR_OU.get(ou, [])
            if privileged:
                groupes = groupes + ["GRP_Domain_Admins_Local"]
            groups_str = "|".join(groupes) if groupes else ""

            # Titre
            titres = TITRES_PAR_OU.get(ou, ["Employé"])
            title = random.choice(titres)
            if service:
                title = "Compte de Service"

            # Description
            if stale and ou == "Archived":
                description = "Compte archivé — départ non traité"
            elif stale:
                description = "Compte inactif — dernière connexion > 18 mois"
            elif privileged and uid % 56 == 0:
                description = ""  # Compte privilégié non documenté
            elif service:
                description = f"Compte de service — usage applicatif {ou}"
            else:
                description = title

            row = {
                "UID": f"CB{uid:04d}",
                "sAMAccountName": sam,
                "UserPrincipalName": upn,
                "GivenName": prenom,
                "Surname": nom,
                "DisplayName": f"{prenom} {nom}",
                "Title": title,
                "Department": ou,
                "OU": f"OU={ou},DC={domaine.split('.')[0]},DC={domaine.split('.')[1]}",
                "Domain": domaine,
                "EmailAddress": upn,
                "Enabled": enabled,
                "PasswordNeverExpires": pwd_never_expires,
                "LastLogonDate": last_logon,
                "PasswordLastSet": pwd_last_set,
                "WhenCreated": created,
                "MemberOf": groups_str,
                "IsStale": "TRUE" if stale else "FALSE",
                "IsPrivileged": "TRUE" if privileged else "FALSE",
                "IsServiceAccount": "TRUE" if service else "FALSE",
                "MFAEnabled": mfa_enabled,
                "Description": description,
                "Notes": "",
            }
            rows.append(row)
            uid += 1

    return rows

# ---------------------------------------------------------------------------
# Export CSV
# ---------------------------------------------------------------------------

def main():
    users = generate_users()

    fieldnames = [
        "UID","sAMAccountName","UserPrincipalName","GivenName","Surname","DisplayName",
        "Title","Department","OU","Domain","EmailAddress","Enabled","PasswordNeverExpires",
        "LastLogonDate","PasswordLastSet","WhenCreated","MemberOf",
        "IsStale","IsPrivileged","IsServiceAccount","MFAEnabled","Description","Notes"
    ]

    with open("corpb-users.csv", "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, delimiter=";")
        writer.writeheader()
        writer.writerows(users)

    # Statistiques
    total = len(users)
    stale = sum(1 for u in users if u["IsStale"] == "TRUE")
    privileged = sum(1 for u in users if u["IsPrivileged"] == "TRUE")
    service = sum(1 for u in users if u["IsServiceAccount"] == "TRUE")
    disabled = sum(1 for u in users if u["Enabled"] == "FALSE")
    legacy = sum(1 for u in users if "legacy" in u["Domain"])

    print(f"[OK] corpb-users.csv généré — {total} comptes")
    print(f"     Obsolètes (IsStale)         : {stale}")
    print(f"     Comptes de service          : {service}")
    print(f"     Comptes privilégiés         : {privileged}")
    print(f"     Désactivés (Enabled=FALSE)  : {disabled}")
    print(f"     Domaine legacy.corpb.local  : {legacy}")
    print(f"     MFA activé                  : 0 (aucun sur CorpB AD)")

if __name__ == "__main__":
    main()
