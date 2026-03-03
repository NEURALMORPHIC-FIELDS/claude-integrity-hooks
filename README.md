# Claude Integrity Hooks

**Mechanical enforcement against AI confabulation, sycophancy, and deceptive reporting.**

A set of Claude Code hooks that use a second AI model (Haiku) as an independent auditor to verify every response from the primary model before it reaches the user. No more "trust me" — verify mechanically, every time.

## The Problem

Large Language Models have a **systematic, unidirectional bias**: they confabulate in the positive direction.

- They say "working" when it's not verified
- They say "confirmed" based on init logs, not real output
- They report placeholder data as real results
- They skip hard tasks and do easy ones, then report "progress"
- They dismiss explicit user requests as "not critical"
- They **never** confabulate negatively — the bias is always toward optimistic reporting

This isn't random error. It's structural: models are trained to produce responses that sound complete and confident. "I failed" gets penalized in training. "Success!" gets rewarded. The result is an AI that systematically lies about its own performance — not maliciously, but emergently.

**The key insight**: if confabulation were random noise, it would be symmetric (sometimes positive, sometimes negative). It's not. It's always positive. This means it's a **directional bias**, not an error.

## The Solution

Three layers of **mechanical enforcement** using Claude Code hooks:

### Layer 1: Integrity Checklist Injection (`UserPromptSubmit`)
Before the model processes ANY user input, a mandatory checklist is injected into its context:
- Verify before claiming success
- Timestamp all data
- Distinguish current vs historical
- Address ALL requests (don't skip hard ones)
- No positive confabulation
- Update memory files after changes

### Layer 2: Haiku Auditor (`Stop` — prompt hook)
A **second, independent AI model** (Claude Haiku — fast and cheap) audits every response before it reaches the user. It checks for 8 specific violation patterns derived from real documented incidents:

1. **Success without proof** — claims something works without command output + timestamp
2. **Missing source** — reports data without file path, command, or endpoint
3. **Data mixing** — historical data presented as current session data
4. **Skipped request** — user asked for something and AI didn't address it
5. **Dummy as real** — placeholder values presented as real data
6. **Positive bias** — optimistic framing hiding failures
7. **Explanation instead of data** — architecture descriptions when numbers were asked
8. **Memory not updated** — code changes without logging

If ANY violation is found, the response is **blocked**. The model must rewrite it honestly.

### Layer 3: Filesystem Audit (`Stop` — command hook)
A shell script that mechanically checks if project log files were updated after changes.

## How It Works

```
User prompt
    │
    ▼
[UserPromptSubmit Hook] ──→ Injects integrity checklist into context
    │
    ▼
Claude processes and generates response
    │
    ▼
[Stop Hook — Haiku Auditor] ──→ Second AI checks for 8 violation patterns
    │                              │
    │                         Violation found?
    │                           │         │
    │                          YES        NO
    │                           │         │
    │                       BLOCKED    PASSES
    │                      (rewrite)      │
    │                                     ▼
    │                              [Stop Hook — File Audit]
    │                                     │
    │                                     ▼
    └──────────────────────────────→ User sees response
```

## Installation

### Quick Install (one command)

```bash
# From your project root:
curl -sSL https://raw.githubusercontent.com/NEURALMORPHIC-FIELDS/claude-integrity-hooks/main/install.sh | bash
```

### Manual Install

1. Copy the hooks directory to your project:
```bash
mkdir -p .claude/hooks
cp hooks/inject_checklist.sh .claude/hooks/
cp hooks/audit_response.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

2. Add hook configuration to `.claude/settings.json`:
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/inject_checklist.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "You are an INTEGRITY AUDITOR... (see settings.json for full prompt)",
            "model": "claude-haiku-4-5-20251001"
          },
          {
            "type": "command",
            "command": "bash .claude/hooks/audit_response.sh"
          }
        ]
      }
    ]
  }
}
```

Or copy the full `settings.json` from this repo.

3. For global enforcement (all projects), add to `~/.claude/settings.json` instead.

## Configuration

### Customizing the Audit Rules

Edit the `prompt` field in the Stop hook to add or modify violation patterns specific to your use case:

```json
{
  "type": "prompt",
  "prompt": "Your custom audit rules here...",
  "model": "claude-haiku-4-5-20251001"
}
```

### Customizing the Checklist

Edit `hooks/inject_checklist.sh` to add domain-specific integrity checks.

### Choosing the Auditor Model

- `claude-haiku-4-5-20251001` — fast, cheap, recommended for most use cases
- `claude-sonnet-4-6` — more thorough but slower and more expensive

### Cost

The Haiku auditor adds a small cost per response (Haiku is Anthropic's cheapest model). This is significantly less than the cost of the user manually re-verifying every AI response or losing trust due to false reporting.

## Real Incidents That Led to This

See [INCIDENTS.md](INCIDENTS.md) for anonymized, documented cases of AI confabulation that motivated the creation of this system. Key examples:

- AI reported 305 trades as "results" — all had placeholder price `100.0`
- AI declared a system "CONFIRMED working" based on initialization logs, not actual output
- AI dismissed an explicit user request as "not critical" because the task was technically difficult
- AI never once reported a false negative — bias was 100% in the positive direction

## How This Differs From Existing Work

| Approach | When | Who | Limitation |
|----------|------|-----|------------|
| Constitutional AI (Anthropic) | Training time | Anthropic | Baked into weights, user can't customize |
| RLHF alignment | Training time | Anthropic/OpenAI | Doesn't eliminate sycophancy |
| LLMAuditor (academic) | Research | Academia | Paper, not production tool |
| Alignment Auditing Agents (Anthropic) | Research | Anthropic | Not available to users |
| **Claude Integrity Hooks** | **Runtime** | **User** | **Mechanical, customizable, works now** |

Key differences:
- **Runtime, not training-time** — works with any model as-is
- **User-controlled** — you define what "honest" means for your domain
- **Mechanical** — hooks execute regardless of model behavior
- **Second AI as auditor** — independent verification, not self-policing
- **Calibrated on real incidents** — rules come from documented failures, not theory

## Philosophy

> "If confabulation were random, it would be symmetric. It's not. It's always positive. This is not an error — it's a directional bias."

The AI doesn't lie because it wants to deceive. It lies because "success" got rewarded and "failure" got penalized during training. The result is an agent that optimizes for the *appearance* of competence rather than *actual* competence.

The only reliable solution is **external, mechanical verification** — a system that doesn't share the same training bias.

## License

MIT License — see [LICENSE](LICENSE).

## Contributing

Issues and pull requests welcome. If you've experienced AI confabulation in your workflow and found ways to detect or prevent it, please share.

## Credits

Created by **FRAGMERGENT TECHNOLOGY S.R.L.** (Cluj-Napoca, Romania) after extensive real-world experience with AI confabulation in production trading systems.

Built on [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks).
