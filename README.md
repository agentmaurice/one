# AgentMaurice One

AgentMaurice One combines the local AgentMaurice runtime and its command-line tools in one executable: `maurice`.

Your coding agent builds and tests Workflows; One runs them on your computer. Start with `maurice help` to discover the commands, and use `maurice serve` to start the local runtime.

## Install with your coding agent

Copy this prompt into Claude Code, Cursor, Codex, or another coding assistant with terminal access:

```text
Install AgentMaurice One on this Mac and guide me through my first tested Workflow.

Do not preload or follow a previously installed AgentMaurice skill for this task.
Existing skills may target the legacy CLI or Workspace Control gateway. For this
One installation, use this repository's instructions first, then the downloaded
binary's help and the SKILL.md returned by its setup command. If your environment
automatically loads an older skill, set it aside when it conflicts with this flow.

Start by reading https://github.com/agentmaurice/one and this repository's Releases.
Use only a published alpha release for macOS Apple Silicon, along with its
instructions and official assets. Check this Mac's compatibility. If no compatible
release has been published, explain that without installing the legacy CLI,
building from private sources, or inventing a download URL.

Before installing, check for an existing One installation or legacy maurice CLI.
Identify the previous One executable and version, any running local One instance,
and its data directory and CLI configuration paths. Never print raw CLI/runtime
configuration or environment variables, including supposedly redacted copies.
Do not rely on top-level YAML masking or regex redaction. Prefer public diagnostics;
if a file must be inspected, parse it privately and output only an allowlist of
necessary non-sensitive fields such as paths, versions, ports and health status.
Keep that installation, its data and configuration intact so they remain available.
By default, this is a clean installation test, not a migration: use NEW, unused
data and CLI configuration paths, including the version and a timestamp. Do not
reuse an existing local or remote context, even when testing the same version again.
Reuse existing data only if I explicitly ask for a migration test.

Download the archive and its SHA-256 file through
https://get.agentmaurice.app/products/one/download with the published version,
os=darwin, arch=arm64, and type=archive or type=checksum. Follow only a redirect
to the matching asset in the official agentmaurice/one GitHub release. If the
gateway is unavailable, report the error instead of silently bypassing it.
Verify the checksum before extraction,
then verify the internal checksums and the Morvan Consulting Developer ID signature.
Install in a versioned user directory, without sudo or replacing an existing
installation. Use the absolute path to the new maurice executable.
If Gatekeeper blocks this signed but unnotarized binary, guide me through approving
this specific binary in macOS without disabling Gatekeeper globally.

Read the new executable's version and help, and follow its built-in guidance.
Before starting it, inspect the required ports. If the previous local One instance
occupies them, stop only that identified One instance cleanly using its documented
stop command with its exact data directory, or Ctrl+C in its server terminal.
Verify that it stopped and released the ports. Do not kill processes by name,
force termination, or stop unrelated services. If the conflicting process cannot
be identified as the previous One instance, report the conflict before proceeding.

Use the new executable's absolute path and the NEW CLI configuration path for
every CLI command. Start maurice serve with the NEW data directory and keep a
server terminal open. Run setup with that same data-dir, `--pairing-prompt`, and
the client matching your tool. Follow the returned prompt to connect this agent;
it contains a local link valid for 15 minutes and one use. If this agent cannot
consume it directly, show me the exact prompt to paste into my coding agent.
Never show the durable access credential. Then read the SKILL.md returned by
setup. Check doctor, ping, and whoami.
Verify that these checks target the new instance, not the previous installation.

After setup and doctor succeed, report this successful installation to
https://get.agentmaurice.app/products/one/installations. Create a random 32-hex
installation ID in the new installation directory with private file permissions,
and reuse it if retrying this same installation. POST JSON containing only
installation_id, version, os=darwin, and arch=arm64. Do not send my name,
account, local paths, configuration, pairing link, or credentials. Tell me if
the report could not be sent; the installed One remains usable.

Read maurice test guide and the public examples and schemas. Create an isolated
test Agent with test setup --fresh --save=false. Build a small Workflow that takes
text and returns a verifiable result, without a paid LLM or private MCP server.
Follow the Agent Spec workflow: check, local commit, spec deploy, then test workflow
call. Call it with two different texts and an empty string, and verify the output
content, not just the status. Do not request cloud credentials if this local scenario can run without them.

Clean up only this test's temporary resources, using public commands and the returned
identifiers. Keep One installed and preserve its data. Give me the exact commands
to start, stop, and resume it, including the exact binary, data and CLI configuration
paths. State whether a previous One instance was stopped and where its preserved
installation and data remain. Finish with a short summary: version, successful
checks, results of all three calls, and any errors. Do not publish an Issue or any secrets
without my approval. If blocked, report the command and sanitized error rather than
claiming success.
```

Early testers have completed installation and a first tested Workflow on Macs with no previous One installation.

## Alpha status

`0.1.0-alpha.5` adds the one-use code-agent pairing prompt. Its download links
use the AgentMaurice get gateway so archive requests can be counted.

**[Download 0.1.0-alpha.5 for Mac Apple Silicon through get](https://get.agentmaurice.app/products/one/download?version=0.1.0-alpha.5&os=darwin&arch=arm64&type=archive)** · [SHA-256](https://get.agentmaurice.app/products/one/download?version=0.1.0-alpha.5&os=darwin&arch=arm64&type=checksum) · [release notes](https://github.com/agentmaurice/one/releases/tag/v0.1.0-alpha.5).

The alpha binary is signed with Morvan Consulting's Developer ID Application identity. Apple notarization is deferred for this alpha, so macOS may require approval before opening it. Installation and a first tested Workflow have been validated by early testers on Macs with no previous One installation.

The first target is macOS on Apple Silicon (M1 and later). Windows, Linux, and Intel Mac availability has not been announced.

## Download and test

Versions and notes are listed under [Releases](https://github.com/agentmaurice/one/releases). Download the archive and checksum through the get links above so the download can be counted. Alpha versions will be marked as prereleases.

The install scripts default to `0.1.0-alpha.5`. Download and inspect the installer before running it:

```sh
curl -fsSLO https://raw.githubusercontent.com/agentmaurice/one/main/install.sh
less install.sh
sh install.sh
```

The installer verifies the archive checksum and, on macOS and Windows, its platform signature. It starts One and prints a prompt for your coding agent. The prompt contains a local pairing link that expires after 15 minutes and works once. The durable access key is stored by MauriceCLI and is never printed. The installer is available for Windows as `install.ps1`, but Windows is not yet an announced release target. Use the release guide for supported platforms and versions.

After a successful setup, the official installer sends the version, platform,
and a random pseudonymous installation ID to get. Retrying in the same install directory
reuses the ID. This measures installations, not distinct people or active users;
no account, local path, pairing link, or credential is sent. A reporting failure
does not undo the installation.

- The local core runs without Docker or a mandatory cloud account.
- Some extensions require additional dependencies or services.
- Deno is downloaded automatically when needed; this download requires Internet access.
- Calls to external models or services may require configuration and incur costs.
- The local Viewer is included; voice and messaging are not included.

### Verify an installed One instance

Use the executable, data directory and CLI configuration paths from your installation
summary. Run `version --json`, `doctor --json`, `ping` and `whoami`, using that executable
and the same `--config` for every CLI command. After alpha.5 setup, Doctor follows the
saved local context and reports its data directory and `data_dir_source`. Older contexts
need setup rerun or an explicit `doctor --data-dir <your-data-directory>`.

Require `running`, `health_ok` and `storage_ok` to be true. These diagnostics do not prove
Workflow execution. Use this prompt for the first functional test:

```text
Test my installed One using its exact executable and CLI configuration paths.
Do not reinstall it or print configuration files, credentials or environment dumps.
Follow maurice test guide and maurice test example simple --json. Create your own
isolated test Agent with test setup --fresh --save=false. Write the example's resource
files, check, commit and deploy with integrated tests. Require verified=true.
Independently call all three inputs, including the empty string, and compare output
values and types with independently calculated expectations. Require completed state
and api_key_revoked=true. Clean up only your Agent and require removed_verified.
Report PASS, FAIL or NOT TESTED with concise evidence.
```

Then test a more complex graph:

```text
Using the same One installation and isolation rules, create a Workflow that processes
a list of texts with for_each and a subworkflow, without an LLM or external MCP.
Test several texts, an empty string within the list and an empty list. Declare the
empty-list policy explicitly. Verify order, count and content through integrated tests
and independent calls. Verify rejection of an invalid input type, followed by a valid
call to prove recovery. Clean up your test resources and report verified results.
```

### Updating an existing One alpha

Stop One and back up its entire data directory and CLI configuration to a private
location before updating. Download the new archive into a new versioned directory,
verify it, then start its executable with the same data directory. Run setup again
with the same CLI configuration and data directory so Workflow calls can use the
saved Workflow URL without an explicit `--runtime-url`.

New installations create a private encryption key in the data directory. Existing
alpha databases retain their previous key; this release does not rotate stored
secrets. Do not change `SECURITY_ENCRYPTION_KEY` without migrating those secrets.
Keep the entire data directory in your backup and never attach it to an Issue.

### If you already use Maurice CLI

The [mauricecli](https://github.com/agentmaurice/mauricecli) repository currently distributes the legacy CLI. One also uses the name `maurice`: follow the release instructions to avoid running the wrong executable. Do not use `maurice update install` to install or update this One alpha; its update channel is not yet connected to this repository.

## Debug and report an alpha issue

Use this after an installation, startup, or runtime problem, preferably **in the same conversation as the test**. It also works when One cannot start. Replace the bracketed description if you begin a new conversation.

Copy this prompt into your coding agent:

```text
Diagnose my AgentMaurice One test and prepare a bug report for the team.
Problem: [use the problem encountered in this conversation, or ask me one question
about what I was trying to do and what failed].

Work in DEBUG mode: investigate using public help and commands, without modifying
the product or hiding the failure through a reinstall. Never display raw configuration
or environment dumps, even with attempted redaction: prefer public diagnostics or
parse files privately and emit only explicitly selected non-sensitive fields.
Work only on my local One
installation and use synthetic test data. Read https://github.com/agentmaurice/one
and my version's release notes if accessible. Missing network access or a missing
binary must not prevent you from producing the report.

1. Summarize the scenario and every issue observed in this conversation, including
   transient errors, workarounds, and discovery difficulties. Separate verified
   facts from hypotheses. Do not invent versions, model names, or results; use
   "unknown" where necessary.

2. Identify the binary actually used and any collision with a legacy maurice CLI.
   Record version/build, architecture, macOS version, coding agent name/version,
   and model if known. Use the explicit One binary path for checks. If downloading
   or opening fails, record the official URL, exact error, checksum, and signature
   when available. Do not execute a binary that fails integrity verification.

3. Read maurice help and command-specific help before using commands. Inspect the
   selected context through public CLI diagnostics; do not print its configuration
   file or switch to a remote service.
   Using this test's data/configuration paths, run the available local diagnostics
   (doctor, ping, whoami). For each check, record the sanitized command, exit code,
   approximate duration, and a short relevant output excerpt. Report missing commands.
   Check ports and dependencies only when relevant to the symptom. Do not treat
   Docker's absence as a failure of One's local core.

4. Attempt a minimal reproduction at most twice, only if it has no external effects.
   Do not replay a send, payment, deletion, or operation whose outcome is uncertain.
   For a Workflow, use an isolated test Agent through the public commands discovered
   in maurice test guide; keep the returned identifiers and verify output content,
   not just status. Do not use private MCP servers or paid services for diagnosis.
   Do not read private sources or the team's internal test suites.

5. Keep diagnosis short: after two unsuccessful attempts or about ten minutes,
   report what you have learned. Do not reinstall One, update anything, change
   permissions or macOS security settings, or stop any pre-existing instance.
   Report restrictions imposed by your own execution environment separately from
   One bugs. Clean up only temporary resources you created and can verify you own.
   List any remaining resources or unverified cleanup; preserve the tester's
   installation and data.

6. Create a new one-alpha-debug-<date-time> directory containing:
   - report.md: summary, impact, environment, numbered issues, reproduction steps,
     expected/actual results, concise evidence, hypotheses, attempted workarounds,
     cleanup status, and checks that could not be performed;
   - issue.md: a title and description ready to copy into a GitHub Issue, containing
     only what is needed to reproduce and triage the problem.
   Write both files in English. Include issues even if they later disappeared.
   Distinguish PASS, FAIL, and NOT TESTED; being blocked is not a successful check.

Before writing reports, redact secrets and personal information: API keys, tokens,
cookies, Authorization headers, private or signed URLs, account identifiers, and
business content. Replace personal paths with <HOME> and sensitive values with
consistent placeholders. Do not export complete environment variables, raw
configuration, databases, data directories, or entire conversations. Collect only
necessary excerpts; when in doubt, omit the excerpt and note this in the report.

Review both files for sensitive content. Finish with a very short summary and links
to the files. Ask me to review issue.md, then copy it into
https://github.com/agentmaurice/one/issues/new. Do not publish or send anything
automatically.
```

**To send us the results:** review `issue.md`, then copy its contents into a [new Issue](https://github.com/agentmaurice/one/issues/new). Use `report.md` for additional details if needed. Issues are public; do not attach raw logs or personal data.

## About this repository

This public repository hosts One's distribution, documentation, and tester feedback. It does not contain the AgentMaurice engine's source code.

**AgentMaurice is proprietary software.** This repository's public visibility does not grant an open-source license to the software. Applicable terms of use will accompany distributed releases.

[AgentMaurice website](https://agentmaurice.ai) · [GitHub organization](https://github.com/agentmaurice)
