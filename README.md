# IAProd

Absolument. Voici un tutoriel d'exécution détaillé, adapté aux différents environnements, notamment pour les utilisateurs Windows qui ont le choix entre WSL et PowerShell.

---

### Tutoriel d'Exécution Complet

Ce guide vous explique comment déployer la stack IA de A à Z. La méthode recommandée pour les utilisateurs Windows est d'utiliser **WSL2**, car le script est écrit en Bash (`.sh`) et Docker Desktop a des performances optimales avec WSL2.

---

### Étape 0 : Pré-requis (À faire une seule fois)

Avant de lancer le script, assurez-vous que votre système est prêt.

#### Pour tous les utilisateurs :
1.  **GPU NVIDIA** : Assurez-vous d'avoir une carte graphique NVIDIA.
2.  **Pilotes NVIDIA** : Installez les derniers pilotes depuis le site de NVIDIA.
3.  **Git** : Installez Git. Sur Linux, `sudo apt-get install git`. Sur Windows, téléchargez-le depuis [git-scm.com](https://git-scm.com/download/win).

#### Pour Windows (Recommandé : WSL2) :
1.  **Installer WSL2** : Si ce n'est pas déjà fait, ouvrez PowerShell en tant qu'administrateur et tapez :
    ```powershell
    wsl --install
    ```
    Cela installera WSL2 et une distribution Ubuntu par défaut. Redémarrez votre ordinateur après l'installation.
2.  **Installer Docker Desktop** : Téléchargez et installez [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/). Durant l'installation, assurez-vous que l'option **"Use WSL 2 based engine"** est cochée.
3.  **Ouvrir un terminal WSL** : Une fois tout installé, ouvrez votre terminal Ubuntu (via le menu Démarrer).
4.  **Installer `aria2c` dans WSL** : Dans votre terminal Ubuntu, tapez :
    ```bash
    sudo apt-get update && sudo apt-get install -y aria2
    ```

#### Pour Linux (Ubuntu/Debian) :
1.  **Installer Docker Engine** : Suivez le [guide officiel](https://docs.docker.com/engine/install/ubuntu/) pour installer Docker Engine et le plugin Compose.
2.  **Installer le NVIDIA Container Toolkit** : Suivez le [guide officiel de NVIDIA](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) pour permettre à Docker d'utiliser votre GPU.
3.  **Installer `aria2c`** :
    ```bash
    sudo apt-get update && sudo apt-get install -y aria2
    ```

---

### Étape 1 : Préparation du Projet

1.  **Choisissez un emplacement** pour votre projet. Par exemple, `C:\Users\VotreNom\projets\ia_stack` sur Windows ou `/home/votre_nom/projets/ia_stack` sur Linux.
2.  **Créez les 4 fichiers de configuration** à cet emplacement :
    *   `deploy.sh`
    *   `config.sh`
    *   `.env`
    *   `.gitignore`
3.  **Copiez-collez le contenu** de chaque fichier (fourni dans ma réponse précédente) dans le fichier correspondant.

---

### Étape 2 : Configuration Personnalisée

Avant de lancer quoi que ce soit, vous devez vérifier deux choses :

1.  **Ouvrez `config.sh`** :
    *   **IMPORTANT** : Modifiez la variable `BASE_DIR`. Elle doit pointer vers le dossier que vous venez de créer.
        *   **Si vous utilisez WSL**, le chemin Windows `C:\Users\VotreNom\projets\ia_stack` devient `/mnt/c/Users/VotreNom/projets/ia_stack`.
        *   **Si vous utilisez Linux**, le chemin sera par exemple `/home/votre_nom/projets/ia_stack`.
    *   Ajustez les ports si nécessaire.

2.  **Ouvrez `.env`** :
    *   **ACTION REQUISE** : Changez la valeur de `POSTGRES_PASSWORD` pour un mot de passe fort et secret.

---

### Étape 3 : Exécution du Script

C'est ici que l'environnement que vous utilisez est important.

#### Méthode 1 : Windows avec WSL2 (La Voie Recommandée)

1.  **Ouvrez votre terminal WSL** (Ubuntu).
2.  **Naviguez jusqu'au dossier de votre projet**. Utilisez la syntaxe Linux pour les chemins Windows :
    ```bash
    # Exemple si votre projet est dans C:\Users\VotreNom\projets\ia_stack
    cd /mnt/c/Users/VotreNom/projets/ia_stack
    ```
3.  **Rendez le script exécutable**. C'est une étape à ne faire qu'une seule fois.
    ```bash
    chmod +x deploy.sh
    ```
4.  **Lancez le script !**
    ```bash
    ./deploy.sh
    ```

#### Méthode 2 : Linux Natif ou macOS

1.  **Ouvrez un terminal**.
2.  **Naviguez jusqu'au dossier de votre projet** :
    ```bash
    cd /home/votre_nom/projets/ia_stack
    ```
3.  **Rendez le script exécutable** :
    ```bash
    chmod +x deploy.sh
    ```
4.  **Lancez le script** :
    ```bash
    ./deploy.sh
    ```

#### Méthode 3 : Windows avec Git Bash (Alternative si vous n'avez pas WSL2)

Si vous avez installé Git for Windows, vous avez aussi "Git Bash". C'est un terminal qui comprend les commandes Linux.

1.  **Allez dans votre dossier de projet** dans l'Explorateur de Fichiers Windows.
2.  **Faites un clic droit** et sélectionnez **"Git Bash Here"**.
3.  Une fenêtre de terminal s'ouvre, déjà positionnée dans le bon dossier.
4.  **Rendez le script exécutable** :
    ```bash
    chmod +x deploy.sh
    ```
5.  **Lancez le script** :
    ```bash
    ./deploy.sh
    ```

#### Qu'en est-il de PowerShell ?

Le script `deploy.sh` est un script **Bash**. **Il ne peut pas être exécuté directement dans PowerShell.** Vous devez obligatoirement utiliser un interpréteur Bash comme ceux fournis par **WSL** ou **Git Bash** pour lancer le déploiement initial.

Cependant, une fois la stack lancée, **PowerShell est parfait pour gérer Docker** avec les commandes `docker compose ps`, `docker compose down`, etc.

---

### Étape 4 : Suivi et Vérification

1.  Le script va s'exécuter, en affichant chaque étape.
2.  Il effectuera les vérifications, vous demandera une confirmation, puis commencera les téléchargements et la construction. **Soyez patient**, cela peut prendre beaucoup de temps.
3.  Une fois le script terminé, il affichera un message de succès avec les URL des services.
4.  Ouvrez un **nouveau terminal** (PowerShell, WSL, ou autre) et vérifiez que tout est bien lancé :
    ```bash
    # Naviguez vers le dossier défini dans BASE_DIR
    cd /mnt/c/Users/VotreNom/projets/ia_stack
    
    # Listez les conteneurs en cours d'exécution
    docker compose ps
    ```
    Vous devriez voir 5 services avec le statut `running` (ou `up`).

### Étape 5 : Accès et Gestion

*   **Accédez aux interfaces web** via les URL fournies (ex: `http://localhost:8080`).
*   **Pour gérer votre stack** (arrêter, redémarrer), utilisez les commandes `docker compose` depuis le dossier de votre projet (`BASE_DIR`) :
    ```bash
    # Pour tout arrêter
    docker compose down

    # Pour tout redémarrer
    docker compose up -d
    ```
