# SOP: Contributing New Components

How to contribute a new skill, agent, rule, or pattern to the cc-framework.

---

## Step 1: Determine the Right Layer

| Question | Layer |
|----------|-------|
| Does every engineer need this regardless of client or domain? | **Core (Layer 1)** |
| Is this specific to a discipline (data eng, analytics, ML)? | **Domain (Layer 2)** |
| Is this specific to a cloud platform (GCP, AWS, Azure)? | **Platform (Layer 3)** |
| Is this specific to one client engagement? | **Client (Layer 4)** |

**Rule: Start at the most specific layer. Promote upward as the pattern proves universal.**

A pattern proven on one engagement starts in Layer 4 (client). If it works across multiple engagements in the same domain, promote to Layer 2. If it works across all domains, promote to Layer 1.

---

## Step 2: Choose the Right Mechanism

| Need | Mechanism |
|------|-----------|
| Repeatable developer workflow | **Skill** |
| Complex isolated reasoning task | **Agent** |
| Persistent instruction/constraint | **Rule** |
| External tool connection | **MCP Server config** |
| Lifecycle automation | **Hook** |

See `docs/architecture/decision-framework.md` for detailed guidance.

---

## Step 3: Follow the Component Pattern

### Skill Format

Create `skills/<skill-name>/SKILL.md`:

```markdown
---
name: skill-name
description: One-line description of what this skill does
---

# Skill Name

## When to Use
<!-- When should a developer invoke this skill -->

## Workflow
<!-- Step-by-step instructions Claude Code follows -->

### Step 1: ...
### Step 2: ...

## Output Format
<!-- What the skill produces -->
```

### Agent Format

Create `agents/<agent-name>.md`:

```markdown
---
name: agent-name
description: One-line description
model: sonnet
maxTurns: 15
tools: Read, Write, Grep, Glob
---

# Agent Name

## Purpose
<!-- What this agent does -->

## Instructions
<!-- Detailed instructions for the agent -->

## Output Format
<!-- What the agent produces -->
```

### Rule Format

Create `rules/<rule-name>.md`:

```markdown
---
description: What this rule enforces
globs: "*.py"
---

# Rule Name

## Standards
<!-- The standards/constraints this rule enforces -->
```

---

## Step 4: Write Documentation

Every component needs:
1. **Clear description** in the file's frontmatter
2. **When to use** section explaining the trigger/use case
3. **What it produces** section describing outputs
4. **Examples** of expected behavior

---

## Step 5: Test in Isolation

### Skills
1. Invoke the skill in a test project
2. Verify each step executes correctly
3. Test with different inputs (green-field vs. brown-field, different platforms)
4. Verify output format matches specification

### Agents
1. Spawn the agent via Task tool
2. Verify it produces the expected output documents
3. Test with edge cases (missing input, conflicting requirements)
4. Check that tool usage is appropriate (not over-using WebSearch, etc.)

### Rules
1. Create test files matching the rule's glob pattern
2. Ask Claude Code to write code — verify the rule is followed
3. Intentionally violate the rule — verify Claude Code catches it
4. Check rule doesn't conflict with existing rules

---

## Step 6: Submit PR

Follow `CONTRIBUTING.md`:

1. Fork the repository (or create a branch if you have write access)
2. Create your component in the correct layer directory
3. Update the relevant catalog doc (`docs/reference/skills-catalog.md`, etc.)
4. Write a clear PR description:
   - What the component does
   - Which layer and why
   - How you tested it
   - Link to the engagement/project that inspired it

---

## Promotion Pipeline

```
Project-specific → Domain module → Core
(Layer 4)         (Layer 2)       (Layer 1)
```

### Promotion Criteria

**Layer 4 → Layer 2:**
- Used successfully on 2+ engagements in the same domain
- No client-specific assumptions in the code
- Documented with examples from multiple engagements

**Layer 2 → Layer 1:**
- Used successfully across 2+ domains
- No domain-specific assumptions
- Approved by framework maintainers
- Full documentation and tests

### How to Promote

1. Copy the component from its current layer to the target layer
2. Remove any layer-specific assumptions (client names, platform-specific code)
3. Generalize the instructions/rules
4. Submit a PR with the promotion justification
5. Link to the original component and the engagements where it was validated
