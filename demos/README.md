# Démonstrations de k8sGPT pour le Troubleshooting Kubernetes

Ce dépôt contient des exemples de configurations Kubernetes pour démontrer comment **k8sGPT** peut aider à diagnostiquer et résoudre des problèmes courants dans un cluster Kubernetes.

---

## Table des matières
- [Introduction](#introduction)
- [Prérequis](#prérequis)
- [Démonstrations](#démonstrations)
  - 1. Pod en état `Pending`
  - 2. Pod en état `ErrImagePull`
  - 3. Pod en état `CrashLoopBackOff`
  - 4. Pod en état `OOMKilled`
  - 5. Erreur de configuration `Ingress`
  - 6. Service sans `endpoints`
- [Comment utiliser ces fichiers avec k8sGPT ?](#comment-utiliser-ces-fichiers-avec-k8sgpt-)

---

## Introduction
[k8sGPT](https://github.com/k8sgpt-ai/k8sgpt) est un outil basé sur l'IA qui aide les opérateurs Kubernetes à diagnostiquer et résoudre les problèmes dans leurs clusters. Il utilise des modèles d'IA pour analyser les ressources Kubernetes et fournir des recommandations de résolution.

Ce dépôt fournit des exemples de configurations YAML pour reproduire des erreurs courantes, ainsi que des instructions pour utiliser k8sGPT afin de les diagnostiquer.

## Prérequis
- Un cluster Kubernetes (local ou cloud)
- `kubectl` configuré pour accéder à votre cluster
- k8sGPT installé
- Un backend IA configuré (OpenAI, LocalAI, etc.)

## Démonstrations

### 1. Pod en état Pending (problème de nodeAffinity ou taints)
Ce fichier crée un Pod qui ne peut pas être planifié à cause d'une nodeAffinity trop restrictive ou de taints non tolérés.
> Fichier : `pod-pending.yaml`

### 2. Pod en état ErrImagePull (image introuvable)
Ce fichier crée un Pod qui essaie de tirer une image qui n'existe pas.
> Fichier : `pod-errimagepull.yaml`

### 3. Pod en état ErrImagePull (mauvais identifiants pour un registre privé)
Ce fichier crée un Pod qui essaie de tirer une image depuis un registre privé avec de mauvais identifiants.
> Fichier : `pod-errimagepull-auth.yaml`

### 4. Pod en état CrashLoopBackOff (commande invalide)
Ce fichier crée un Pod qui crash en boucle car la commande spécifiée n'existe pas dans l'image.
> Fichier : `pod-crashloopbackoff.yaml`

### 5. Pod en état OOMKilled (dépassement de mémoire)
Ce fichier crée un Pod qui consomme toute la mémoire disponible, déclenchant un OOMKilled.
> Fichier : `pod-oomkilled.yaml`

### 6. Erreur de configuration Ingress (classe ou service inexistant)
Ce fichier crée un Ingress qui référence une classe ou un service inexistant.
> Fichier : `ingress-error.yaml`

### 7. Service sans endpoints
Ce fichier crée un Service qui n'a pas d'endpoints associés (pas de Pods avec les bons labels).
> Fichier : `service-no-endpoints.yaml`

## Comment utiliser ces fichiers avec k8sGPT ?

- Appliquez les fichiers dans votre cluster :
`kubectl apply -f pod-pending.yaml` 

- Lancez k8sGPT pour analyser les problèmes :
`k8sgpt analyze --explain --namespace=dev`

- Utilisez le mode interactif pour poser des questions spécifiques :
`k8sgpt analyze --explain --namespace=dev --interactive`




