#!/bin/bash
# ==============================================================================
# SCRIPT DE DÉPLOIEMENT v8 (Totalement Robuste)
#
# Ce script utilise des fichiers de configuration externes, vérifie le système
# et déploie une stack IA complète de manière sécurisée et modulaire.
# ==============================================================================

set -e # Arrête le script en cas d'erreur

# --- GESTION DES INTERRUPTIONS ---
# Si l'utilisateur fait Ctrl+C, on tente de nettoyer les conteneurs.
function cleanup {
  echo -e "\n[INFO] Interruption détectée. Tentative de nettoyage..."
  if [ -f "$BASE_DIR/docker-compose.yml" ]; then
    cd "$BASE_DIR"
    docker compose down --remove-orphans > /dev/null 2>&1
    echo "[INFO] Les conteneurs ont été arrêtés."
  fi
  echo "[INFO] Nettoyage terminé."
  exit 1
}
trap cleanup SIGINT SIGTERM

# --- FONCTIONS DE VÉRIFICATION ---

function check_files() {
  echo "[ÉTAPE 1/7] Vérification des fichiers de configuration..."
  if [ ! -f "config.sh" ] || [ ! -f ".env" ]; then
    echo "[ERREUR] Les fichiers 'config.sh' et/ou '.env' sont introuvables."
    echo "Veuillez vous assurer qu'ils existent dans le même dossier que ce script."
    exit 1
  fi
  source config.sh
  echo "[OK] Fichiers de configuration chargés."
}

function check_dependencies() {
  echo "[ÉTAPE 2/7] Vérification des dépendances logicielles..."
  for cmd in docker git aria2c; do
    if ! command -v $cmd &> /dev/null; then
      echo "[ERREUR] La commande '$cmd' est introuvable. Veuillez l'installer."
      exit 1
    fi
  done
  if ! docker compose version &> /dev/null; then
    echo "[ERREUR] 'docker compose' (plugin V2) est introuvable. Mettez à jour Docker."
    exit 1
  fi
  echo "[OK] Toutes les dépendances sont présentes."
}

function check_system_resources() {
  echo "[ÉTAPE 3/7] Vérification des ressources système..."
  # Vérification de l'accès au GPU
  if ! docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo "[ERREUR] Docker ne semble pas pouvoir accéder au GPU NVIDIA."
    echo "Vérifiez l'installation des pilotes NVIDIA et du NVIDIA Container Toolkit."
    exit 1
  fi
  echo "[OK] L'accès au GPU est fonctionnel."

  # Vérification de l'espace disque
  mkdir -p "$BASE_DIR"
  local available_space_gb=$(df -BG "$BASE_DIR" | awk 'NR==2 {print substr($4, 1, length($4)-1)}')
  if (( available_space_gb < MIN_DISK_SPACE_GB )); then
    echo "[ATTENTION] Espace disque faible : ${available_space_gb}Go disponibles (minimum recommandé : ${MIN_DISK_SPACE_GB}Go)."
    read -p "Voulez-vous continuer quand même ? (y/n) " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 1; fi
  fi
  echo "[OK] Espace disque suffisant."
}

# --- FONCTIONS DE DÉPLOIEMENT ---

function create_project_files() {
  echo "[ÉTAPE 4/7] Création des fichiers de projet (Docker, Compose)..."
  # Création de la structure de dossiers
  mkdir -p $BASE_DIR/data/comfyui/{models,custom_nodes,input,output,workflows}
  mkdir -p $BASE_DIR/data/{ollama,n8n,postgres,open-webui}
  mkdir -p $BASE_DIR/comfyUI # Pour le Dockerfile

  # Création du Dockerfile pour ComfyUI
  cat << 'EOF' > $BASE_DIR/comfyUI/Dockerfile.optimized
FROM pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime
RUN apt-get update && apt-get install -y git wget ffmpeg xz-utils aria2 libgl1 libglib2.0-0 python3-pip && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/comfyanonymous/ComfyUI /ComfyUI
WORKDIR /ComfyUI
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir opencv-python-headless==4.10.0.82 imageio-ffmpeg==0.4.9
ENV PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:64
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all,compute,utility
EXPOSE 8188
CMD ["python","main.py","--listen","0.0.0.0","--port","8188","--lowvram"]
EOF

  # Création du docker-compose.yml en utilisant les variables de config.sh et .env
  cat << EOF > $BASE_DIR/docker-compose.yml
version: '3.8'
services:
  ollama:
    image: ollama/ollama
    container_name: ollama
    deploy: {resources: {reservations: {devices: [{driver: nvidia, count: 1, capabilities: [gpu]}]}}}
    volumes: ["./data/ollama:/root/.ollama"]
    networks: ["ia-network"]
    restart: unless-stopped
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    ports: ["${OPEN_WEBUI_PORT}:8080"]
    volumes: ["./data/open-webui:/app/backend/data"]
    networks: ["ia-network"]
    depends_on: [ollama]
    environment: ['OLLAMA_BASE_URL=http://ollama:11434']
    restart: unless-stopped
  comfyui:
    build: {context: ./comfyUI, dockerfile: Dockerfile.optimized}
    container_name: comfyui
    ports: ["${COMFYUI_PORT}:8188"]
    volumes:
      - ./data/comfyui/input:/ComfyUI/input
      - ./data/comfyui/output:/ComfyUI/output
      - ./data/comfyui/models:/ComfyUI/models:ro
      - ./data/comfyui/custom_nodes:/ComfyUI/custom_nodes
      - ./data/comfyui/workflows:/ComfyUI/workflows
    networks: ["ia-network"]
    deploy: {resources: {reservations: {devices: [{driver: nvidia, count: 1, capabilities: [gpu]}]}}}
    restart: unless-stopped
  postgres:
    image: postgres:16
    container_name: n8n-postgres
    environment:
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_DB: \${POSTGRES_DB}
    volumes: ["./data/postgres:/var/lib/postgresql/data"]
    networks: ["ia-network"]
    restart: unless-stopped
  n8n:
    image: docker.n8n.io/n8nio/n8n
    container_name: n8n
    ports: ["${N8N_PORT}:5678"]
    environment:
      DB_TYPE: postgresdb
      DB_POSTGRESDB_HOST: postgres
      DB_POSTGRESDB_DATABASE: \${POSTGRES_DB}
      DB_POSTGRESDB_USER: \${POSTGRES_USER}
      DB_POSTGRESDB_PASSWORD: \${POSTGRES_PASSWORD}
      GENAI_ENDPOINT_URL: http://ollama:11434/api
    volumes: ["./data/n8n:/home/node/.n8n"]
    networks: ["ia-network"]
    depends_on: [postgres, ollama]
    restart: unless-stopped
networks:
  ia-network: {driver: bridge}
EOF
  echo "[OK] Fichiers de projet créés dans $BASE_DIR."
}

function download_assets() {
  echo "[ÉTAPE 5/7] Téléchargement des plugins et modèles..."
  # Téléchargement des plugins ComfyUI
  echo "[INFO] Clonage/Mise à jour des plugins ComfyUI..."
  for plugin_url in "\${COMFYUI_PLUGINS[@]}"; do
    plugin_name=\$(basename "\$plugin_url" .git)
    target_dir="$BASE_DIR/data/comfyui/custom_nodes/\$plugin_name"
    if [ -d "\$target_dir" ]; then
      echo "  -> Mise à jour de \$plugin_name..."
      (cd "\$target_dir" && git pull)
    else
      echo "  -> Clonage de \$plugin_name..."
      git clone "\$plugin_url" "\$target_dir"
    fi
  done
  echo "[INFO] Le téléchargement des modèles ComfyUI va commencer (cela peut être très long)..."
  # Ici, vous pouvez ajouter le long script de téléchargement des modèles ComfyUI si nécessaire,
  # ou le laisser à l'utilisateur pour qu'il les ajoute manuellement dans ./data/comfyui/models.
  # Pour la simplicité de ce script, nous laissons cette partie manuelle.
  echo "[OK] Plugins téléchargés. Les modèles ComfyUI sont à placer manuellement dans ./data/comfyui/models."
}

function launch_stack() {
  echo "[ÉTAPE 6/7] Lancement de la stack Docker..."
  cd "$BASE_DIR"
  docker compose up --build -d
  echo "[OK] Tous les services sont en cours de démarrage."

  echo "[ÉTAPE 7/7] Initialisation des modèles Ollama..."
  echo "[INFO] Attente du démarrage du service Ollama..."
  sleep 10
  for model in $OLLAMA_MODELS; do
    echo "[INFO] Téléchargement du modèle Ollama : $model..."
    docker exec ollama ollama pull "$model"
  done
  echo "[OK] Modèles Ollama initialisés."
}

# --- EXÉCUTION PRINCIPALE ---
main() {
  clear
  echo "=================================================================="
  echo "    Déploiement de la Stack IA - Version Robuste v8"
  echo "=================================================================="
  
  check_files
  check_dependencies
  check_system_resources

  echo "------------------------------------------------------------------"
  echo "Le script va maintenant effectuer les actions suivantes :"
  echo "1. Créer la structure de projet dans : $BASE_DIR"
  echo "2. Télécharger les plugins ComfyUI."
  echo "3. Construire l'image Docker pour ComfyUI."
  echo "4. Lancer les 5 services de la stack IA."
  echo "5. Télécharger les modèles de base pour Ollama."
  echo "------------------------------------------------------------------"
  read -p "Êtes-vous prêt à continuer ? (y/n) " -n 1 -r; echo
  if [[ ! \$REPLY =~ ^[Yy]\$ ]]; then
    echo "Opération annulée."
    exit 0
  fi

  create_project_files
  download_assets
  launch_stack

  echo "
##################################################################
#                                                                #
#      L'ENVIRONNEMENT EST DÉPLOYÉ ET PRÊT !                     #
#                                                                #
##################################################################

Les services sont en cours d'exécution.

------------------------------------------------------------------
ACCÈS À VOS SERVICES
------------------------------------------------------------------
- ComfyUI      : http://localhost:${COMFYUI_PORT}
- n8n          : http://localhost:${N8N_PORT}
- Ollama WebUI : http://localhost:${OPEN_WEBUI_PORT}

------------------------------------------------------------------
GESTION DE L'ENVIRONNEMENT (depuis le dossier $BASE_DIR)
------------------------------------------------------------------
- Arrêter tous les services : docker compose down
- Redémarrer les services   : docker compose restart
- Voir les logs d'un service: docker compose logs -f <nom_du_service>
"
}

main "$@"