# AzureX #27 – Introduction à K8sGPT
## 🎯 Objectif
Découvrir K8sGPT, un outil open source qui analyse votre cluster Kubernetes et fournit des diagnostics intelligents grâce à l’IA.

## ✅ Qu’est-ce que K8sGPT ?
K8sGPT est un diagnostic tool pour Kubernetes qui :

- Inspecte l’état de votre cluster (pods, nodes, services, etc.)
- Détecte les problèmes courants (CrashLoopBackOff, erreurs de configuration, quotas)
- Explique les causes et propose des pistes de résolution
- Peut s’intégrer avec des LLMs pour enrichir les explications


## 🔍 Pourquoi l’utiliser ?

- Gain de temps : plus besoin de fouiller dans les logs pour comprendre un problème
- Amélioration du support : aide les équipes à diagnostiquer rapidement
- Compatible multi-cloud : fonctionne sur AKS, EKS, GKE, clusters on-prem


## 🛠️ Installation rapide
### Installer via Homebrewbrew 
install k8sgpt-ai/k8sgpt/k8sgpt
### Vérifier la version
k8sgpt version

## 🚀 Utilisation de base

### Scanner le cluster
k8sgpt analyze

### Scanner avec un filtre (ex: namespace)

k8sgpt analyze --namespace production

### Activer l’IA (nécessite une clé API)

k8sgpt auth add --provider openai --model gpt-4 --api-key <clé>

## 🔗 Intégrations

- Azure OpenAI : pour enrichir les diagnostics
- Prometheus : corrélation avec les métriques
- GitOps : intégration dans les pipelines CI/CD


## 📚 Ressources

- https://k8sgpt.ai
- https://github.com/k8sgpt-ai/k8sgpt
- https://docs.k8sgpt.ai


## 💡 Tips pour la démo

1. Préparer un cluster AKS avec un pod en erreur (CrashLoopBackOff)
2. Montrer la différence entre kubectl describe et k8sgpt analyze
3. Activer l’IA pour expliquer le problème en langage naturel