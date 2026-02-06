# Mythic Frontiers - Design Outline

## 1) Core Pillars

1. **Grand strategy, simplified**: campaign and army management with quick resolution.
2. **Mythic alien warfare**: each race has mystical identity and battlefield flavor.
3. **Readable combat math**: small dice-based model with tactical positioning bonuses.
4. **Meaningful progression**: city growth and unit experience create long-term momentum.

## 2) Factions

Each race has 3 unit variants (early -> mid -> elite), unlocked by city tier.

### A) Aetherkin Concord
- **Starborne Spearhost** (Tier 1): disciplined line infantry.
- **Solar Mantle Wardens** (Tier 2): armored defenders with radiant shields.
- **Astral Seraphim** (Tier 3): elite shock troops with mythic aura.

### B) Chthonic Brood
- **Burrowclaw Swarmers** (Tier 1): fast melee packs.
- **Sporehorn Ravagers** (Tier 2): brutal heavy attackers.
- **Eclipse Carapace Titans** (Tier 3): resilient behemoths.

### C) Tempest Clans
- **Stormrider Reavers** (Tier 1): mobile skirmishers.
- **Thunder Totem Guard** (Tier 2): balanced assault infantry.
- **Skyfang Mythhunters** (Tier 3): elite hunters with precision strikes.

## 3) Combat Model (Dice-Based)

For each attack:

1. Roll `1d6` for attacker and defender.
2. Compute attack power:
   - `attack_stat + d6 + mythic_power + position_bonus`
3. Compute defense power:
   - `defense_stat + d6`
4. Damage = `max(1, attack_power - defense_power + weapon_damage)`

### Position Bonuses
- **Front**: `+0`
- **Flank**: `+2`
- **Rear**: `+4`

This preserves tactical depth without heavy complexity.

## 4) Campaign & Development

Cities can be upgraded through 3 tiers:
- **Tier 1 Outpost**: unlocks basic units.
- **Tier 2 Citadel**: unlocks mid-tier units, grants modest army bonus.
- **Tier 3 Mythic Nexus**: unlocks elite units, grants stronger empire bonus.

### City Bonuses
- Economic growth (faster expansion).
- Military logistics (army-wide defense/attack modifier).
- Arcane infrastructure (mythic power growth multiplier).

## 5) Unit Progression

Units gain XP from battles:
- Rank up every XP threshold.
- Each rank increases mythic power and reputation.

### Effects
- **Mythic Power**: contributes to combat calculations.
- **Reputation**: can later influence morale, diplomacy, and upkeep.

## 6) MVP Loop

1. Expand to acquire/upgrade cities.
2. Recruit units unlocked by city tier.
3. Fight battles using quick dice resolution.
4. Level units into mythic veterans.
5. Snowball through strategic development choices.
