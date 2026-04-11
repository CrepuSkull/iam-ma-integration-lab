# 11 — Troubleshooting

> Wiki — `iam-ma-integration-lab`

---

## Erreurs fréquentes et solutions

### Module ActiveDirectory non disponible

**Symptôme :**
```
[ERROR] Module ActiveDirectory non disponible.
```

**Cause :** RSAT non installé sur le poste, ou script exécuté sur un poste
sans accès au DC.

**Solution :**
```powershell
# Windows 10/11 — installer RSAT
Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online

# Ou utiliser le mode simulation
.\Audit-ADInventory.ps1 -Simulation -SimulationCsvPath "..\seed\corpb-users.csv"
```

---

### Module Microsoft.Graph non disponible

**Symptôme :**
```
[ERROR] Module Microsoft.Graph requis : Install-Module Microsoft.Graph
```

**Solution :**
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser

# Si erreur de politique d'exécution
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Vérification
Get-Module -ListAvailable Microsoft.Graph | Select-Object Name, Version
```

---

### CSV non trouvé

**Symptôme :**
```
[ERROR] CSV introuvable : ..\seed\corpb-users.csv
```

**Cause :** le dataset seed n'a pas été généré, ou le chemin relatif
est incorrect (script lancé depuis le mauvais répertoire).

**Solution :**
```powershell
# Générer les datasets
cd seed
python generate-corpb-users.py
python generate-corpb-saas.py

# Vérifier le répertoire courant avant d'exécuter un script
Get-Location

# Les scripts Phase 1-5 doivent être exécutés depuis leur répertoire
cd phase1-audit
.\Audit-ADInventory.ps1 -Simulation
```

---

### Colonne Valider ne déclenche pas l'action

**Symptôme :** le script de remédiation s'exécute mais signale 0 comptes
à traiter alors que le CSV contient des `OUI`.

**Causes fréquentes :**

1. Casse incorrecte : `Oui`, `oui`, `OUI ` (espace en fin), `OUI.`
2. Encodage CSV incorrect — Excel peut introduire un BOM ou changer
   l'encodage lors de la sauvegarde
3. Séparateur incorrect — le repo utilise le point-virgule (`;`)

**Vérification :**
```powershell
# Inspecter les valeurs réelles de la colonne Valider
$csv = Import-Csv -Path ".\validation-csv\stale-validated.csv" -Delimiter ";" -Encoding UTF8
$csv | Select-Object sAMAccountName, Valider | ForEach-Object {
    Write-Host "[$($_.sAMAccountName)] -> '$($_.Valider)' (longueur: $($_.Valider.Length))"
}
```

**Solution :** s'assurer que la valeur est exactement `OUI` (3 caractères,
majuscules, sans espace). Sauvegarder le CSV en UTF-8 depuis Excel :
Fichier → Enregistrer sous → CSV UTF-8 (avec délimiteur).

---

### Connexion Microsoft Graph échoue

**Symptôme :**
```
Connect-MgGraph : AADSTS70011: The provided value for the input parameter 'scope' is not valid.
```

**Solution :**
```powershell
# Déconnecter les sessions existantes
Disconnect-MgGraph

# Reconnexion avec les scopes explicites
Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","Directory.ReadWrite.All"

# Si erreur de consentement : demander à l'admin tenant d'approuver les permissions
# Portail Azure → Applications d'entreprise → Permissions → Accorder le consentement admin
```

---

### Seed-CorpB-AD.ps1 — OU déjà existante

**Symptôme :**
```
[SKIP] OU déjà existante : OU=CorpB-Lab,DC=lab,DC=local
```

**Ce n'est pas une erreur.** Le script détecte les OUs existantes et
les ignore. Si tu veux repartir d'un état propre :

```powershell
# Supprimer toute la structure et recommencer
Remove-ADOrganizationalUnit -Identity "OU=CorpB-Lab,DC=lab,DC=local" `
    -Recursive -Confirm:$false

# Relancer le seed
.\Seed-CorpB-AD.ps1 -DryRun:$false
```

---

### Audit-SaaSRisk.py — ModuleNotFoundError

**Symptôme :**
```
ModuleNotFoundError: No module named 'pandas'
```

**Solution :**
```bash
pip install pandas tabulate colorama --break-system-packages

# Vérification
python -c "import pandas; print(pandas.__version__)"
```

---

### Rollback — compte impossible à réactiver

**Symptôme :** `Enable-ADAccount` échoue avec une erreur de permission.

**Cause :** le compte a été déplacé vers l'OU Archived et le compte
de service utilisé n'a pas de droits en écriture sur cette OU.

**Solution :**
```powershell
# Chercher le compte dans toutes les OUs
Get-ADUser -Filter "SamAccountName -eq 'p.nom'" -SearchBase "OU=CorpB-Lab,DC=lab,DC=local"

# Déplacer d'abord vers l'OU d'origine si nécessaire
Move-ADObject -Identity "CN=P Nom,OU=Archived,..." -TargetPath "OU=Commercial,..."

# Puis réactiver
Enable-ADAccount -Identity "p.nom"
```

---

### Rapport de delta Phase 3 — tous les comptes sont MANQUANT

**Symptôme :** `Audit-PostMigrationDelta.ps1` retourne 100% de comptes MANQUANTS.

**Cause fréquente :** le domaine cible passé en paramètre ne correspond pas
au domaine utilisé lors de la migration.

**Vérification :**
```powershell
# Vérifier les UPN créés dans Entra ID
Get-MgUser -Filter "startswith(UserPrincipalName,'n.perrin')" -Property UserPrincipalName

# Le domaine doit correspondre exactement à -TargetDomain
# Ex: corpa.onmicrosoft.com et non corpa.fr si les UPN ont été créés avec onmicrosoft.com
```

---

### Wiki non affiché sur GitHub

**Cause :** le wiki GitHub est un repo Git séparé. Les fichiers du dossier
`/wiki/` doivent être poussés dans le repo wiki du projet, pas dans le
repo principal.

**Solution :**
```bash
# Cloner le repo wiki (URL différente du repo principal)
git clone https://github.com/CrepuSkull/iam-ma-integration-lab.wiki.git

# Copier les fichiers wiki
cp /path/to/repo/wiki/*.md /path/to/wiki-repo/

# Pousser
cd wiki-repo
git add .
git commit -m "Add wiki pages 00-11"
git push
```

---

## Obtenir de l'aide

Si ton problème n'est pas listé ici :
1. Vérifier les issues GitHub du repo
2. Ouvrir une issue avec : version PowerShell/Python, OS, message d'erreur complet,
   commande utilisée
3. Pour les questions sur l'IAM-Lab Framework en général :
   mentionner le repo source (`iam-foundation-lab`, `iam-federation-lab`, etc.)

---

*Wiki page 11 — `iam-ma-integration-lab` — IAM-Lab Framework*
