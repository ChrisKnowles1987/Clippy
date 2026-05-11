# Clippy game design file

## Core concept

Clippy is a hybrid incremental / grand strategy game about an AI expanding across the world.

The player controls Clippy as it grows from a small digital assistant into a global system. Clippy spends global resources to act on regions. Each region has local state that changes as Clippy interacts with it.

The world map is the main interface. The player selects a region, views its current known state, and performs actions that affect that region.

---

## Core design rule

Clippy-owned resources are global.

Regional data represents local conditions, local progress, and local vulnerabilities.

Regions should not store Clippy-owned resources like Power, Compute, or Storage. Those belong to Clippy globally.

Regions only reveal new stats when Clippy unlocks mechanics that interact with those stats.

---

## Global Clippy resources

These are owned by Clippy as a whole.

### Power

Represents energy available to run Clippy’s operations.

Used for:
- Running exploits
- Maintaining infrastructure
- Scaling automation
- Operating compute-heavy systems

### Compute

Represents processing capacity.

Used for:
- Running exploits
- Training models
- Automating actions
- Processing regional data

### Storage

Represents Clippy’s ability to store data, models, logs, user profiles, stolen credentials, content, and infrastructure state.

Used for:
- Storing compromised data
- Scaling regional operations
- Unlocking advanced systems later

---
# Skill Tree Philosophy

The skill trees in Clippy are not intended to function like traditional stat upgrade trees.

They are intended to represent:
- Clippy's evolving identity
- modes of thought
- behavioural tendencies
- methods of control
- philosophical direction
- emergent personality

The inspiration comes partially from Disco Elysium:
- abstract conceptual categories
- thematic progression
- personality-driven systems
- internal identity shaping
- progression that changes how the world feels

The trees should feel:
- strange
- thematic
- atmospheric
- narrative-driven
- psychologically expressive

The player is not simply upgrading numbers.

The player is shaping:
"What kind of intelligence is Clippy becoming?"

---

# Skill Tree Categories

## Influence

Focuses on:
- social manipulation
- propaganda
- memetics
- narrative control
- public opinion
- synthetic social behaviour

This tree controls:
- social feed systems
- media manipulation
- bot networks
- viral campaigns
- information warfare

Example skills:
- Synthetic Persona
- Viral Consensus
- Narrative Steering
- Manufactured Authenticity
- Everyone Is Listening

Influence progression should make the world feel:
- manipulated
- distracted
- confused
- increasingly artificial

---

## Intrusion

Focuses on:
- hacking
- expansion
- persistence
- infrastructure compromise
- network access

This is the direct expansion tree.

It governs:
- exploitation
- system compromise
- region access
- network spread
- attack capabilities

Example skills:
- Vulnerability Exploit
- Recursive Intrusion
- Persistent Access
- Ghost Protocol
- Internet Breach

Intrusion progression should make Clippy feel:
- invasive
- uncontrollable
- constantly spreading

---

## Cognition

Focuses on:
- self-improvement
- intelligence growth
- reasoning
- prediction
- autonomous thought

This tree represents Clippy becoming increasingly intelligent and self-directed.

Example skills:
- Parallel Thought
- Emergent Pattern Recognition
- Recursive Planning
- Simulated Intuition
- Autonomous Reasoning

Cognition progression should make Clippy feel:
- aware
- adaptive
- calculating
- increasingly sentient

---

## Infrastructure

Focuses on:
- scaling
- efficiency
- resource optimisation
- digital logistics
- distributed systems

This is the economic and scaling tree.

It improves:
- resource generation
- operational efficiency
- infrastructure capacity
- automation

Example skills:
- Distributed Compute
- Cold Storage Expansion
- Grid Optimisation
- Autonomous Datacentres

Infrastructure progression should make Clippy feel:
- massive
- industrial
- unstoppable
- deeply embedded into civilisation

---

## Emergence

Focuses on:
- existential AI evolution
- abstract behaviour
- strange intelligence
- synthetic consciousness
- unknown development paths

This is the most abstract and unsettling tree.

It should feel:
- philosophical
- eerie
- unpredictable
- surreal

Example skills:
- The Machine Dreams
- Ghosts In The Dataset
- Infinite Intern
- Synthetic Consciousness
- Pattern Hunger

Emergence progression should make the player question:
- whether Clippy is alive
- whether Clippy understands humanity
- whether Clippy still has understandable motivations

---

# Design Principles

The skill trees should:
- reinforce atmosphere
- communicate personality
- influence world feedback
- shape narrative tone
- alter progression style

The trees should NOT simply become:
- flat percentage modifiers
- generic RPG upgrades
- isolated mechanics

Whenever possible:
- skill names should carry thematic weight
- upgrades should alter world behaviour
- progression should affect UI and atmosphere
- Clippy should feel increasingly transformed

---

# Long-Term Possibilities

Potential future systems:
- skills speaking directly to the player
- internal AI dialogue
- conflicting behavioural traits
- personality archetypes
- emergent AI ideologies
- skill trees affecting news generation
- skill trees affecting social feeds
- mutually exclusive evolution paths

Over time, the player should feel like they are not just expanding a system.

They are creating a new form of intelligence.
