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

## Starting global resources

For early testing:

```text
Power: 10
Compute: 10
Storage: 0
