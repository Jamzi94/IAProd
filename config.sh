#!/bin/bash
# ==============================================================================
# FICHIER DE CONFIGURATION PRINCIPAL
# Modifiez les variables ici pour personnaliser votre déploiement.
# ==============================================================================

# --- CHEMINS ---
# Le répertoire racine où tout sera installé.
# IMPORTANT : Utilisez un chemin absolu.
export BASE_DIR="/mnt/e/Projets"

# --- PORTS DES SERVICES ---
# Modifiez ces valeurs si les ports par défaut sont déjà utilisés sur votre machine.
export OPEN_WEBUI_PORT="8080"
export COMFYUI_PORT="8188"
export N8N_PORT="5678"

# --- MODÈLES OLLAMA ---
# Liste des modèles à installer au démarrage, séparés par des espaces.
export OLLAMA_MODELS="llama3:8b-instruct codestral"

# --- PLUGINS COMFYUI (CUSTOM NODES) ---
# Liste des dépôts Git pour les custom nodes. Ajoutez ou supprimez des lignes ici.
export COMFYUI_PLUGINS=(
  "https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved"
  "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite"
  "https://github.com/ltdrdata/ComfyUI-Manager"
)

# --- RESSOURCES SYSTÈME ---
# Espace disque minimum requis en Go. Le script vous avertira si l'espace est inférieur.
export MIN_DISK_SPACE_GB=50
