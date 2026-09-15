# AgentMaurice One

AgentMaurice One réunit le runtime local AgentMaurice et sa ligne de commande dans un exécutable : `maurice`.

Votre agent de code construit et teste des Workflows ; One les exécute sur votre poste. `maurice help` est le point d’entrée de découverte, et `maurice serve` démarre le runtime local.

## État de l’alpha

**Première distribution Mac Apple Silicon en préparation. Aucun binaire n’est encore publié ici.**

Le candidat alpha est signé avec l’identité Developer ID Application de Morvan Consulting. La notarisation Apple est différée pour cette alpha ; macOS peut donc demander une autorisation d’ouverture. Le parcours d’installation sur un Mac vierge reste à valider avant publication.

La première cible est macOS sur Apple Silicon (M1 et générations suivantes). Aucune disponibilité Windows, Linux ou Mac Intel n’est annoncée à ce stade.

## Télécharger et tester

Les versions seront disponibles dans les [Releases](https://github.com/agentmaurice/one/releases), avec l’archive, sa somme de contrôle SHA-256, les instructions d’installation et les limites connues. Les versions alpha seront identifiées comme préversions.

Le guide de chaque version fera foi pour l’installation et le premier test. Aucun script d’installation One n’est encore publié.

- Le socle local fonctionne sans Docker et sans compte cloud obligatoire.
- Certaines extensions nécessitent des dépendances ou des services supplémentaires.
- Deno est téléchargé automatiquement lorsqu’il est nécessaire ; prévoir un accès Internet pour ce téléchargement.
- Les appels à des modèles ou services externes peuvent demander une configuration et occasionner des coûts.
- Le Viewer de MiniApps, la voix et les messageries ne sont pas inclus dans cette première archive alpha.

### Si vous utilisez déjà Maurice CLI

Le dépôt [mauricecli](https://github.com/agentmaurice/mauricecli) distribue actuellement la CLI historique. One utilise également le nom `maurice` : suivez les instructions de la release pour éviter de lancer le mauvais exécutable. N’utilisez pas `maurice update install` pour installer ou mettre à jour cette alpha One : son canal de mise à jour n’est pas encore raccordé à ce dépôt.

## Signaler un problème

Ouvrez une [Issue](https://github.com/agentmaurice/one/issues) avec :

- la version de One et la version de macOS ;
- le résultat attendu et le résultat observé ;
- les étapes minimales pour reproduire le problème ;
- si un agent de code intervient, son nom, son modèle et le prompt utilisé.

Les Issues sont publiques. Avant de joindre un extrait, retirez les clés API, jetons, données personnelles et informations confidentielles. Ne joignez pas votre répertoire de données One ni une configuration complète.

## À propos de ce dépôt

Ce dépôt public accueille la distribution de One, sa documentation et les retours des testeurs. Il ne contient pas les sources du moteur AgentMaurice.

**AgentMaurice est un logiciel propriétaire.** La visibilité publique de ce dépôt ne confère pas de licence open source au logiciel. Les conditions d’utilisation applicables accompagneront les versions distribuées.

[Site AgentMaurice](https://agentmaurice.ai) · [Organisation GitHub](https://github.com/agentmaurice)
