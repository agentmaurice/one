# AgentMaurice One

AgentMaurice One combines the local AgentMaurice runtime and its command-line tools in one executable: `maurice`.

Your coding agent builds and tests Workflows; One runs them on your computer. Start with `maurice help` to discover the commands, and use `maurice serve` to start the local runtime.

## Install with your coding agent

Copy this prompt into Claude Code, Cursor, Codex, or another coding assistant with terminal access:

```text
Install AgentMaurice One on this Mac and guide me through my first tested Workflow.

Start by reading https://github.com/agentmaurice/one and this repository's Releases.
Use only a published alpha release for macOS Apple Silicon, along with its
instructions and official assets. Check this Mac's compatibility. If no compatible
release has been published, explain that without installing the legacy CLI,
building from private sources, or inventing a download URL.

Download the archive and its SHA-256 file. Verify the checksum before extraction,
then verify the internal checksums and the Morvan Consulting Developer ID signature.
Install in a versioned user directory, without sudo or replacing an existing
installation. Use the absolute path to the new maurice executable.
If Gatekeeper blocks this signed but unnotarized binary, guide me through approving
this specific binary in macOS without disabling Gatekeeper globally.

Read maurice help and follow the built-in guidance. Use dedicated One data and CLI
configuration paths; do not reuse a remote context. Start maurice serve and keep
a server terminal open. Run setup with the same data-dir and the client matching
your tool, then read the SKILL.md returned by setup. Check doctor, ping, and whoami.
If ports are occupied, investigate without stopping or modifying an existing instance.

Read maurice test guide and the public examples and schemas. Create an isolated
test Agent with test setup --fresh --save=false. Build a small Workflow that takes
text and returns a verifiable result, without a paid LLM or private MCP server.
Follow the Agent Spec workflow: check, local commit, spec deploy, then test workflow
call. Call it with two different texts and verify the output content, not just
the status. Do not request cloud credentials if this local scenario can run without them.

Clean up only this test's temporary resources, using public commands and the returned
identifiers. Keep One installed and preserve its data. Give me the exact commands
to start, stop, and resume it. Finish with a short summary: version, successful
checks, results of both calls, and any errors. Do not publish an Issue or any secrets
without my approval. If blocked, report the command and sanitized error rather than
claiming success.
```

The first alpha tester will validate installation on a Mac with no previous One installation.

## Alpha status

**The first Mac Apple Silicon distribution is being prepared. No binary has been published here yet.**

The alpha candidate is signed with Morvan Consulting's Developer ID Application identity. Apple notarization is deferred for this alpha, so macOS may require approval before opening it. Early alpha testers will validate installation on Macs with no previous One installation.

The first target is macOS on Apple Silicon (M1 and later). Windows, Linux, and Intel Mac availability has not been announced.

## Download and test

Versions will be available under [Releases](https://github.com/agentmaurice/one/releases), with the archive, its SHA-256 checksum, installation instructions, and known limitations. Alpha versions will be marked as prereleases.

Follow the guide included with each version for installation and your first test. No One installation script has been published yet.

- The local core runs without Docker or a mandatory cloud account.
- Some extensions require additional dependencies or services.
- Deno is downloaded automatically when needed; this download requires Internet access.
- Calls to external models or services may require configuration and incur costs.
- The MiniApp Viewer, voice, and messaging are not included in this first alpha archive.

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
the product or hiding the failure through a reinstall. Work only on my local One
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
   selected context without displaying secrets; do not switch to a remote service.
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
