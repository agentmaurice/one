# AgentMaurice One

AgentMaurice One réunit le runtime local AgentMaurice et sa ligne de commande dans un exécutable : `maurice`.

Votre agent de code construit et teste des Workflows ; One les exécute sur votre poste. `maurice help` est le point d’entrée de découverte, et `maurice serve` démarre le runtime local.

## Installer avec votre agent de code

Copiez ce prompt dans Claude Code, Cursor, Codex ou votre assistant de code disposant d’un terminal :

```text
Installe AgentMaurice One sur ce Mac et accompagne-moi jusqu’à un premier Workflow testé.

Commence par lire https://github.com/agentmaurice/one et les Releases de ce dépôt.
Utilise uniquement une release alpha publiée pour macOS Apple Silicon, avec ses
instructions et ses fichiers officiels. Vérifie la compatibilité du Mac. S’il
n’y a aucune release compatible publiée, explique-le sans installer la CLI
historique, compiler depuis des sources privées ou inventer un téléchargement.

Télécharge l’archive et son fichier SHA-256, vérifie le checksum avant extraction,
puis les checksums internes et la signature Developer ID Morvan Consulting.
Installe dans un dossier utilisateur versionné, sans sudo ni remplacement d’une
installation existante. Utilise le chemin absolu du nouvel exécutable maurice.
Si Gatekeeper bloque ce binaire signé mais non notarisé, accompagne-moi dans
l’autorisation macOS de ce binaire précis, sans désactiver Gatekeeper globalement.

Lis maurice help et suis les aides embarquées. Utilise un répertoire de données
One et une configuration CLI dédiés ; ne réutilise pas un contexte distant.
Démarre maurice serve et conserve un terminal serveur ouvert. Effectue setup
avec le même data-dir et le client correspondant à ton outil, puis lis le
SKILL.md indiqué par setup. Vérifie doctor, ping et whoami. Si les ports sont
occupés, diagnostique sans arrêter ni modifier une instance qui existait déjà.

Lis maurice test guide et les exemples/schémas publics. Crée un Agent de test
isolé avec test setup --fresh --save=false. Construis un petit Workflow qui
accepte un texte et retourne un résultat vérifiable, sans LLM payant ni serveur
MCP privé. Utilise le rail Agent Spec : check, commit local, spec deploy,
puis test workflow call. Appelle-le avec deux textes différents et vérifie
le contenu des résultats, pas seulement le statut. Ne demande aucune clé
cloud si ce scénario local peut s’en passer.

Nettoie uniquement les ressources temporaires de ce test avec les commandes
publiques et les identifiants retournés. Conserve One installé et ses données.
Donne-moi les commandes exactes pour le démarrer, l’arrêter et reprendre.
Termine par un bilan court : version, contrôles réussis, résultats des deux
appels et éventuelles erreurs. Ne publie aucune Issue ni aucun secret sans
mon accord. Si tu es bloqué, rapporte la commande et l’erreur expurgée plutôt
que de prétendre avoir réussi.
```

Le premier alpha testeur validera l’installation sur un Mac sans installation précédente de One.

## État de l’alpha

**Première distribution Mac Apple Silicon en préparation. Aucun binaire n’est encore publié ici.**

Le candidat alpha est signé avec l’identité Developer ID Application de Morvan Consulting. La notarisation Apple est différée pour cette alpha ; macOS peut donc demander une autorisation d’ouverture. Le parcours sur un Mac sans installation précédente sera validé par les premiers alpha testeurs.

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
