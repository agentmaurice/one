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

## Diagnostiquer et signaler un problème pendant l’alpha

À utiliser après un problème d’installation, de démarrage ou d’exécution, idéalement **dans la même conversation que le test**. Le diagnostic fonctionne aussi si One ne démarre pas. Remplacez la première ligne entre crochets si vous ouvrez une nouvelle conversation.

Copiez ce prompt dans votre agent de code :

```text
Diagnostique mon essai d’AgentMaurice One et prépare un rapport de bug à transmettre
à l’équipe. Problème : [reprends le problème rencontré dans cette conversation,
ou demande-moi en une seule question ce que je voulais faire et ce qui a échoué].

Tu es en mode DEBUG : cherche la cause avec les aides et commandes publiques,
sans modifier le produit ni masquer l’échec par une réinstallation. Travaille
uniquement sur mon installation locale One et avec des données de test fictives.
Lis https://github.com/agentmaurice/one et les notes de ma version si accessibles.
L’absence de réseau ou de binaire ne doit pas empêcher de produire le rapport.

1. Résume le scénario et tous les problèmes observés dans cette conversation,
   y compris les erreurs transitoires, les contournements et les difficultés
   de découverte. Sépare les faits prouvés des hypothèses. N’invente ni version,
   ni modèle, ni résultat ; indique « inconnu » lorsque nécessaire.

2. Identifie le binaire réellement utilisé et une éventuelle collision avec
   une ancienne CLI maurice. Relève version/build, architecture, version macOS,
   nom/version de l’agent de code et modèle si connus. Utilise le chemin explicite
   du binaire One pour les contrôles. Si le téléchargement ou l’ouverture échoue,
   relève l’URL officielle, le message exact, le checksum et la signature si
   disponibles. N’exécute pas un binaire dont l’intégrité est en défaut.

3. Consulte maurice help et les aides des commandes avant de les utiliser.
   Inspecte le contexte sélectionné sans afficher de secrets ; ne bascule pas
   sur un service distant. Avec les chemins de données/configuration de cet
   essai, lance les diagnostics locaux disponibles (doctor, ping, whoami).
   Note pour chaque contrôle la commande expurgée, le code de sortie, la durée
   approximative et un court extrait utile. Si une commande manque, relève-le.
   Vérifie les ports et dépendances seulement s’ils sont liés au symptôme.
   Ne considère pas Docker absent comme un échec du socle One.

4. Tente une reproduction minimale au plus deux fois si elle est sans effet
   externe. Ne rejoue pas un envoi, un paiement, une suppression ou une opération
   dont le résultat est incertain. Pour un Workflow, utilise un Agent de test
   isolé via les commandes publiques découvertes dans maurice test guide ;
   garde les identifiants retournés et vérifie le contenu de sortie, pas seulement
   le statut. N’utilise aucun MCP privé ni service payant pour le diagnostic.
   Ne lis pas les sources privées ni les suites de tests de l’équipe.

5. Garde le diagnostic court : après deux essais infructueux ou environ dix
   minutes, produis les conclusions disponibles. Ne réinstalle pas One, ne mets
   rien à jour, ne change pas les permissions ou la sécurité macOS et n’arrête
   aucune instance préexistante. Signale les refus de ton propre environnement
   séparément des bugs One. Nettoie uniquement les ressources temporaires que
   tu as créées, avec leur propriété vérifiée. Liste tout résidu ou nettoyage
   non vérifié ; conserve l’installation et les données du testeur.

6. Crée un nouveau dossier one-alpha-debug-<date-heure> avec :
   - report.md : résumé, impact, environnement, problèmes numérotés, étapes de
     reproduction, attendu/observé, preuves courtes, hypothèses, contournements
     tentés, état du nettoyage et contrôles impossibles ;
   - issue.md : titre et description prêts à copier dans une Issue GitHub,
     contenant uniquement les éléments nécessaires pour reproduire et trier.
   Inclue les problèmes rencontrés même s’ils ont ensuite disparu. Distingue
   PASS, FAIL et NON TESTÉ ; un blocage n’est pas une réussite.

Avant d’écrire les rapports, expurge les secrets et informations personnelles :
clés API, tokens, cookies, en-têtes Authorization, liens privés ou signés,
identifiants de compte et contenus métier. Remplace les chemins personnels
par <HOME> et les valeurs sensibles par des marqueurs cohérents. N’exporte
ni variables d’environnement complètes, ni configuration brute, ni base,
ni dossier de données, ni conversation complète. Ne collecte que les extraits
nécessaires ; en cas de doute, omets l’extrait et indique-le dans le rapport.

Relis les deux fichiers pour contrôler leur confidentialité. Termine par un
résumé très court et les liens vers les fichiers. Invite-moi à relire issue.md,
puis à le copier dans https://github.com/agentmaurice/one/issues/new.
Ne publie et n’envoie rien automatiquement.
```

**Pour nous transmettre le résultat :** relisez `issue.md`, puis copiez son contenu dans une [nouvelle Issue](https://github.com/agentmaurice/one/issues/new). Le fichier `report.md` fournit les détails complémentaires si nécessaire. Les Issues sont publiques ; ne joignez pas de logs bruts ou de données personnelles.

## À propos de ce dépôt

Ce dépôt public accueille la distribution de One, sa documentation et les retours des testeurs. Il ne contient pas les sources du moteur AgentMaurice.

**AgentMaurice est un logiciel propriétaire.** La visibilité publique de ce dépôt ne confère pas de licence open source au logiciel. Les conditions d’utilisation applicables accompagneront les versions distribuées.

[Site AgentMaurice](https://agentmaurice.ai) · [Organisation GitHub](https://github.com/agentmaurice)
