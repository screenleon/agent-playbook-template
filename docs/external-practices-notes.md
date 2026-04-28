# External Practices Notes

## OpenAI: use repository-local instruction files and layered documentation

OpenAI guidance around agentic coding emphasizes repository-local instruction files and structured documentation instead of relying on long, one-off chat prompts.

Useful takeaway:

- keep the root instruction file short
- put detailed rules in adjacent docs
- let the agent load only the guidance it needs

Sources:
- https://openai.com/index/harness-engineering/
- https://openai.com/pt-PT/index/introducing-codex/
- https://agents.md/

## Anthropic: use project-level subagents for specialization and context isolation

Anthropic documents project-level subagents under `.claude/agents/`, with filesystem-based Markdown definitions and separate context.

Useful takeaway:

- create small, single-purpose agents
- describe when each agent should be used
- avoid one overloaded universal agent

Sources:
- https://docs.anthropic.com/en/docs/claude-code/tutorials
- https://docs.claude.com/en/api/agent-sdk/subagents

## GitHub Copilot: keep reusable instructions and prompt files inside the repo

GitHub supports repository custom instructions and reusable prompt files.

Useful takeaway:

- store stable repo-wide guidance in `.github/copilot-instructions.md`
- store repeatable prompt assets as version-controlled files

Sources:
- https://docs.github.com/en/copilot/how-tos/custom-instructions/adding-repository-custom-instructions-for-github-copilot
- https://docs.github.com/en/copilot/tutorials/customization-library/prompt-files

## APOSD: Deep Module — simple interface, powerful internals

John Ousterhout's *A Philosophy of Software Design* introduces "Deep Module" as a design quality criterion. The principle: a module is deep when its interface is small relative to the functionality it provides. The inverse — a shallow module — has a large interface for little internal power, forcing callers to carry complexity that should be hidden.

Useful takeaway for agent-driven development:

- prefer abstractions that hide complexity behind a minimal call surface
- an agent calling `PriceCalculator.calculate(orderContext)` is more reliable than one composing `calculateTax(amount, taxRate)` + `applyDiscount(...)` + `convertCurrency(...)` every time — the latter requires the agent to re-discover and re-apply the composition rule on every task
- shallow modules increase prompt complexity: every caller must carry the module's internal logic as context, consuming token budget and introducing inconsistency across sessions

Deep module test: if removing the abstraction forces callers to duplicate logic, the module was deep. If removing it changes nothing about what callers must know, it was shallow.

Source:
- Ousterhout, J. (2018). *A Philosophy of Software Design*. Yaknyam Press.

## Matt Pocock / skills: alignment loop and ubiquitous language as first-party agent practices

The `skills` repository (https://github.com/mattpocock/skills) includes two practices worth internalizing at the framework level:

**Alignment loop (grill-me pattern):** A pre-implementation forcing function where the agent challenges design assumptions, names specific failure scenarios, and requires explicit decisions before code starts. Not a discussion — a structured challenge that surfaces the gap between "it felt explained" and "it was actually specified." Implemented in this playbook as `skills/alignment-loop`.

**Ubiquitous language:** A project-level domain glossary (`UBIQUITOUS_LANGUAGE.md`) that all agents, prompts, and documents must use consistently. Its purpose is not documentation — it is semantic consistency. Without it, the same concept accumulates different names across sessions, forcing agents to re-interpret context and wasting token budget on re-explanation. Implemented in this playbook as `skills/ubiquitous-language`.

Useful takeaway:

- alignment-loop belongs between demand-triage and feature-planning; running it earlier eliminates the largest class of wrong implementations
- ubiquitous-language is a session-persistent artifact; it should be loaded as part of context on every task, not just consulted when writing docs
