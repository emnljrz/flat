# The Bored Game: Complete Game Spec

A two-player, turn-based strategy board game. Think **chess + Game of the Generals**: you move pieces on a grid, but pieces also have HP, Armor, attack range and special abilities.

> **How to read this document:** Sections marked **(Confirmed)** come directly from the game designer. Sections marked **(Assumed)** are interpretations used where the rules were silent. Confirm those before treating them as final.

---

## 1. The Game in 60 Seconds

- Two players, **Blue** and **Red**. Each starts with the **same 22 pieces**.
- **Goal:** kill the opposing **Crown** (the king). The game ends immediately when a Crown dies.
- The board is **13 rows x 11 columns**. **Row 7 is a river.** Only the Phantom can cross it without a bridge (by jumping over the river tile); everyone else must use **bridges**. Nobody can stand on a river tile.
- Pieces **do not capture by moving onto a square**. Instead they **attack at range** when an enemy is in range.
- Damage hits **Armor first, then HP**. Armor never comes back.
- Some attacks (**Burn**, **Poison**) **ignore Armor**.
- Attacking is optional: moving never attacks, and a piece in range is never forced to attack. On your turn you choose ONE action.
- The **Phantom** can kill the Crown in a single hit. The **Crown** has a once-per-game **Summon** to pull the Phantom back next to it (the Phantom cannot attack on the turn it is summoned).
- Stalemates are possible, just like chess. No rule prevents shuffling pieces back and forth.

---

## 2. The Board

**Size:** 13 rows (vertical, numbered 1-13) x 11 columns (horizontal, lettered a-k).

- **Row 1 side** belongs to Player 1 (Blue).
- **Row 13 side** belongs to Player 2 (Red).
- **Row 7** is the **River**.

### River and Bridges (Row 7)

| Column | a | b | c | d | e | f | g | h | i | j | k |
|--------|---|---|---|---|---|---|---|---|---|---|---|
| Row 7  | River | Bridge | Bridge | River | Bridge | Bridge | Bridge | River | Bridge | Bridge | River |

- **River squares** (a7, d7, h7, k7): **no piece may ever be placed or stand here, not even the Phantom.** The Phantom may only jump over them (see Section 4).
- **Bridge squares** (b7, c7, e7, f7, g7, i7, j7): any piece may stand here.
- **Bridge Block:** a piece standing on a Bridge square blocks that square. Nobody can pass through it (this is the normal "no passing through pieces" rule applied to bridges). Bridges are chokepoints.

### Deployment Zones

| Player | Deployment rows |
|--------|-----------------|
| Player 1 (Blue) | Rows 1-3 |
| Player 2 (Red)  | Rows 11-13 |

Rows 4-6 and 8-10 start empty.

### Sample Starting Layout (Player 1 side)

This is only a **sample**. Players may place their pieces freely inside their first 3 rows (except the two fixed pieces below).

| Row | a | b | c | d | e | f | g | h | i | j | k |
|-----|---|---|---|---|---|---|---|---|---|---|---|
| 3 | | | | | | | | | | | |
| 2 | Kn | Kn | Tnk | Kn | Kn | Tnk | Kn | Kn | Tnk | Kn | Kn |
| 1 | Sx | Crwn | H | H | A | A | M | M | Scp | A | Tnk |

**Abbreviations:** Tnk = Tank, H = Healer, A = Archer, M = Mage, Kn = Knight, Sx = Phantom (as written in the sample), Crwn = Crown, Scp = Scepter.

> **Note:** In this sample the Scepter is at i1, but the fixed-position rule says it must start at **k1**. Treat the sample as illustrative only. The rules below take priority.

### Fixed Starting Squares (Confirmed)

| Piece | Player 1 | Player 2 |
|-------|----------|----------|
| Phantom | **a1** | **k13** |
| Scepter | **k1** | **a13** |

Everything else is placed freely within your first 3 rows.

---

## 3. The Pieces

Each player has **22 pieces**.

| Num | Name    | Atk | Range | Attack Direction | HP | Armor | Move |
|-----|---------|-----|-------|------------------|----|-------|------|
| 4   | Tank    | 1   | 1     | Front            | 3  | 3     | 1x1  |
| 2   | Healer  | 1   | 4     | All              | 2  | 2     | 1x1  |
| 3   | Archer  | 1   | 4     | Front / Diagonal | 2  | 0     | 1x1  |
| 2   | Mage    | 2   | 3     | Front / Diagonal | 2  | 2     | 1x1  |
| 8   | Knight  | 1   | 1     | Front            | 2  | 3     | 2x2  |
| 1   | Phantom | 3   | 1     | All              | 1  | 1     | 3x3  |
| 1   | Crown   | 1   | 1     | All              | 1  | 1     | 1x1  |
| 1   | Scepter | 2   | 2     | All              | 1  | 1     | 4x4  |

### What each column means

- **Atk:** damage dealt by one attack.
- **Range:** how many squares away the piece can attack (in a straight line).
- **Attack Direction:** which lines the piece can attack along (see Section 3.1).
- **HP:** health. Hit **after** Armor is gone.
- **Armor:** extra protection. Hit **first**. **Never regenerates.**
- **Move:** how far the piece can move (see Section 4).

### Piece roles (Confirmed abilities)

| Piece | Role | What makes it special |
|-------|------|-----------------------|
| Tank | High Durability | 3 HP + 3 Armor. Hard to kill, weak attack. |
| Knight | Reliable Frontline | Same Armor as a Tank, moves up to 2 squares. Your most numerous piece. |
| Healer | Heal or Poison | Range 4. Can Heal an ally (+1 HP) **or** Attack with Poison (bypasses Armor). |
| Archer | Long Range Sniper | Range 4, but 0 Armor. Fragile. |
| Mage | Instant HP Burn | Atk 2, range 3. Burn damage **bypasses Armor** and goes straight to HP. |
| Phantom | River Crosser / Assassin | Strongest attack (3). Only piece that can cross the river without a bridge. Can kill the Crown in one hit. |
| Scepter | Extreme Mobility | Moves up to 4 squares. Range 2 in all directions. |
| Crown | The King | If it dies, you lose. Has a one-time Summon. |

### 3.1 Direction Definitions

- **Front (Confirmed):** only the **single straight line ahead** of the piece. **Not** diagonal.
  - "Ahead" means toward the enemy side: **up** (increasing row numbers) for Player 1, **down** (decreasing row numbers) for Player 2.
- **Front / Diagonal:** the straight line ahead **plus the diagonals**. *(Confirmed: all four diagonals, forward and backward.)*
- **All:** **Queen-style**, meaning all 8 directions (4 orthogonal + 4 diagonal).

---

## 4. Movement Rules (Confirmed)

- **One move per turn.** You move one piece, one time.
- **No jumping.** A piece cannot move through or leap over any other piece (friend or enemy). The only exception is the Phantom skipping a River tile.
- **No capturing by moving.** You cannot move onto an occupied square. Damage comes from attacks only.
- **Move types:**
  - **1x1:** exactly 1 square in any direction (including diagonals).
  - **2x2 / 3x3 / 4x4:** up to that many squares in a **straight line or diagonal** (Queen-style, but distance-limited). A Knight (2x2) can move 1 or 2 squares in any of the 8 directions.
- **River (Confirmed):** no piece may stand on a River square, not even the Phantom. Only the **Phantom** can cross the river without a bridge, by **jumping/skipping over** the River tile as part of its move. It can never land on a River tile.
- **Everyone else** must cross by walking onto a **Bridge square** and out the other side. They cannot jump or skip over the river.
- **Phantom and bridges:** if the Phantom chooses to use a Bridge, it must **walk onto the Bridge square** like any other piece.
- **Bridge Block:** a piece on a Bridge square stops anyone from passing through it.

---

## 5. Combat and Damage

### 5.1 Core combat rules (Confirmed)

1. **Range makes an attack possible.** If an enemy is within a piece's range and attack direction, that piece can attack it on its owner's turn.
2. **No forced attacks (Confirmed).** A piece in range is never forced to attack. Attacking is a choice you make as your turn's action, and your other pieces stay free to move.
3. **Line of Sight / Human Shield.** Attacks cannot pass through a piece. The **first piece along the line takes the hit**, even if the shooter was aiming at something farther away. This applies to ranged attacks too: if a piece stands in front, **it** takes the damage, whether the damage lands on Armor or HP.
4. **Targeting priority:**
   - If **you** are in range of multiple enemies, **you choose** the target.
   - If **you move into range** of multiple enemies, **they** can attack you on their next turn, and the opponent chooses which of their pieces strikes.
5. **Armor first.** Physical damage reduces Armor to 0 before it touches HP.
6. **No regeneration.** Armor can never be restored.
7. **Kill condition (Confirmed):** a piece is removed when **Total Damage Taken >= HP + Armor**. In practice a piece dies the moment its **HP reaches 0**: Armor only protects HP, so a piece at 0 HP with Armor left is still dead (Confirmed).

### 5.2 Damage math, with examples

Each piece's **kill threshold** is HP + Armor. It is removed when total damage taken is **greater than or equal to** this number (Confirmed).

| Piece | HP + Armor | Dies at total damage of |
|-------|-----------|--------------------------|
| Tank | 3 + 3 = 6 | 6 |
| Knight | 2 + 3 = 5 | 5 |
| Healer | 2 + 2 = 4 | 4 |
| Archer | 2 + 0 = 2 | 2 |
| Mage | 2 + 2 = 4 | 4 |
| Phantom | 1 + 1 = 2 | 2 |
| Crown | 1 + 1 = 2 | 2 |
| Scepter | 1 + 1 = 2 | 2 |

**Example 1:** A Knight (Atk 1) hits a Tank. The Tank's Armor goes 3 → 2. HP is untouched.

**Example 2:** The Phantom (Atk 3) hits a fresh Crown (HP 1, Armor 1). Total damage 3 >= 2, so the Crown dies. This is the **Assassin Rule** (Confirmed): intentional, like the Spy killing a General in Game of the Generals.

**Example 3:** The Scepter (Atk 2) hits a fresh Crown. 2 >= 2, so the Crown dies too. The Scepter can kill a fresh Crown, not just the Phantom.

**Example 4:** A Mage (Atk 2) Burns a Tank. Burn bypasses Armor, so the Tank goes from 3 HP to 1 HP and keeps all 3 Armor.

> **Implementation tip:** apply damage (Armor first, unless Burn or Poison) and remove the piece as soon as `hp <= 0`.

### 5.3 Attack resolution (Confirmed: attacking is a turn action)

- **Moving never attacks.** A piece that moves into range does not attack, and enemies do not hit it automatically. The other player gets a full turn to react (this also stops the Phantom from killing the Crown the instant it arrives).
- **One action per turn:** move a piece, attack with a piece that has a target, (Healer) heal or poison, or Summon.
- **Designer example:** your Tank is in range of an enemy Mage and Archer. You may attack one of them, or move the Tank away. Your opponent may then burst you with the Mage, sacrifice the Archer, or retreat.
- **Targeting:** you choose which piece attacks, and which target if several are in line (the Human Shield still applies).
- **Poison** ticks at the end of the poisoned side's own turn (see Section 6).

---

## 6. Status Effects (Armor Bypass)

| Effect | Source | What it does |
|--------|--------|--------------|
| **Burn** | Mage | Damage is **immediate** and **bypasses Armor**, hitting HP directly. Damage amount = the Mage's Atk (2). *(Assumed)* |
| **Poison** | Healer | **Bypasses Armor.** Deals **-1 HP immediately**, then **-1 HP again after the opponent's 2nd turn** (Confirmed). |
| **Cure** | Healer | Only a Healer can remove Poison from an ally. |

### Poison details (Confirmed)

- **Poison does not stack.** An already-poisoned piece cannot be re-poisoned.
- **Healers cast Poison only on their own turn (Confirmed)**, never as a response during the opponent's attack.
- Timeline: first hit (-1 HP) → opponent turn 1 → your turn → opponent turn 2 → second -1 HP.
- **The key decision:** after a piece is poisoned, its owner can use a Healer to **cure the ally** *or* spend the turn **attacking the enemy**. This trade-off is intended.
- Original wording from the designer's notes: "-1 HP upfront and -1 HP again for the next two End Turns." The clarification above ("triggers after 2 rounds") is the latest confirmed ruling.

---

## 7. Special Unit Roles

### The Healer (Confirmed)

- Chooses its action freely like every other piece; its special actions are heal and poison.
- On **its owner's own turn** (never as a response during the opponent's attack) it may **Heal (+1 HP)** an ally **or** **Attack (Poison)** an enemy.
- The Healer can heal or attack **any target in range** (range 4, all 8 directions). **Heals cannot be blocked by line of sight (Confirmed).** Poison attacks are still blocked by the Human Shield.
- Healing cures Poison. *(Confirmed: healing cannot exceed a piece's starting HP. Assumed: one Heal action both restores 1 HP and removes Poison.)*

### The Crown (Confirmed)

- **If the Crown dies, the game ends** and its owner loses.
- **Panic Button (Summon):** once per game, the Crown can Summon the Phantom to **any adjacent empty square** (1x1 around the Crown).
- **Trade-off:** if the Phantom was elsewhere on the board, it is **teleported back** (it leaves its position).
- If the Phantom is **already dead**, it **cannot** be summoned.
- **No attack on summon (Confirmed):** the Phantom cannot attack on the turn it is summoned. It may attack again only on its owner's next turn, after the opponent has played. Until then it is just there to defend, or to be sacrificed for the Crown.
- The Summon cannot be used a second time, even if the Phantom dies.

---

## 8. Turn Flow Summary

1. Choose **one** action: move a piece, attack with a piece that has a target, (Healer) heal/poison, or use the Crown's Summon.
2. Resolve damage and remove dead pieces.
3. Resolve poison ticks for your pieces.
4. If a Crown died, the game ends. Otherwise the other player goes.

---

## 9. Edge Cases and Rulings

| # | Situation | Ruling | Status |
|---|-----------|--------|--------|
| 1 | Can a piece move onto an enemy to capture it? | No. Damage only comes from attacks. | Confirmed (movement rules) |
| 2 | Damage taken equals HP + Armor exactly: dead? | Yes. Dies when damage taken is **>=** HP + Armor. | Confirmed |
| 3 | Does the Phantom's Atk 3 kill the Crown in one hit? | Yes, by design. | Confirmed |
| 4 | Scepter hits a fresh Crown: dead? | Yes: 2 >= 2. | Confirmed by the kill formula |
| 5 | A friendly piece is in front of the target | It **blocks** the shot. Attacks never pass through pieces. | Confirmed (Human Shield) |
| 6 | Does Armor block Burn or Poison? | No. They hit HP directly. | Confirmed |
| 7 | Can Armor be repaired? | Never. | Confirmed |
| 8 | Can poison stack? | No. | Confirmed |
| 9 | Can two pieces stand on the same Bridge? | No: one piece per square, and a piece on a Bridge blocks it. | Confirmed |
| 10 | Can any piece stand on a River square? | No, not even the Phantom. | Confirmed |
| 11 | Can the Phantom stop on a River square? | No. It can only jump over River tiles. It may walk onto or land on Bridge squares. | Confirmed |
| 12 | Can Summon place the Phantom on a River square? | No: no piece may stand on a River square. | Confirmed |
| 13 | Repeated moves / no one attacking | Stalemate is allowed. No anti-stalemate rule. | Confirmed |
| 14 | What does "Front" mean for Player 2? | Down the board (toward row 1). | Assumed (mirror of Player 1) |
| 15 | Can ranged attacks cross the river and bridges? | Yes, as long as the enemy is in range. | Confirmed |
| 16 | Can the Healer's **heal** be blocked by a piece in front? | No: heals reach any ally in range. | Confirmed |
| 17 | Does the Healer retaliate when an enemy moves into its range? | No. Poison can only be cast on the owner's own turn. (The Healer itself can still be hit.) | Confirmed |
| 18 | Can the Crown Summon on the same turn it is threatened? | Yes; it costs the turn as the Phantom's "move". Summon ends the turn. | Confirmed |
| 19 | Does the summoned Phantom attack on arrival, or hit back when attacked? | No. It cannot attack until its owner's next turn after the opponent has played. | Confirmed |
| 20 | Can the opponent attack a freshly summoned Phantom? | Yes (it acts as a defender or sacrifice). | Confirmed |

### Open questions for the designer

1. Does one Heal also cure Poison?

---

## 10. Glossary

| Term | Meaning |
|------|---------|
| Crown | The king. Kill it to win. |
| Armor | Absorbs damage first. Never regenerates. |
| HP | Health. Hit after Armor is gone. |
| Bypass | Damage that skips Armor (Burn and Poison). |
| Forced Engagement | Dropped rule: pieces in range are not forced to attack. |
| Human Shield | The first piece in a line takes the hit. |
| Queen-style | Orthogonal + diagonal movement or attack (8 directions). |
| Bridge Block | A piece on a Bridge square stops all passage through it. |
| Summon | Crown's once-per-game call-back of the Phantom. |
| Assassin Rule | The Phantom can kill the Crown in one hit. |

---

## 11. Quick Reference for Implementers

- **Board:** 13 x 11. Coordinates: column letter (a-k) + row number (1-13).
- **State per piece:** type, owner, current HP, current Armor, poison counter.
- **Kill check:** `hp <= 0` after applying damage (Armor absorbed first; Burn and Poison go straight to HP).
- **Per player:** `summonUsed` flag. **Per Phantom:** a flag that blocks attacking until its owner's next turn after a Summon.
- **Movement:** Queen-style, distance-limited, blocked by any piece; River squares are Phantom-only.
- **Attack lookup:** for each allowed direction, walk outward up to `range` squares; the **first piece found** is the only possible target (an enemy), otherwise the line is blocked.
- **Win condition:** a Crown is removed.