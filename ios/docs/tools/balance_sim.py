#!/usr/bin/env python3
"""Pacing simulator for AshVault.

Mirrors `Balance.swift` `// MARK: - Progression` and combat approximations.
Edit the PACING dict below when retuning — keep names aligned with Balance.swift.

Usage:
    python3 balance_sim.py                    # default tuning
    python3 balance_sim.py --gold-scale 0.45  # what-if gold
    python3 balance_sim.py --layer-growth 0.10
"""
import argparse
import math

# ── Sync with Balance.swift `// MARK: - Progression` ──────────────────────────
PACING = {
    "gold_reward_scale": 0.55,
    "shop_price_growth": 1.7,
    "mercenary_price_growth": 1.14,
    "prestige_shard_divisor": 100.0,
    "fortune_gold_per_level": 0.06,
    "enemy_base_hp": 50,
    "enemy_base_atk": 15,
    "enemy_base_def": 5,
    "enemy_scale_hp": 18,
    "enemy_scale_atk": 16,
    "enemy_scale_def": 6,
    "enemy_boss_hp": 20,
    "enemy_boss_atk": 12,
    "campaign_layer_growth": 0.06,
    "enemy_endless_hp_growth": 1.10,
    "enemy_endless_atk_growth": 1.06,
    "boss_relic_drop_percent": 18,
    "relic_duplicate_gold": 40,
    "auto_shop_max_mercenaries": 1,
    "auto_battle_heal_threshold_percent": 35,
}

# ── Combat approximations (Balance.swift combat/moves) ─────────────────────
MANA_REGEN = 2
MAGIC_BONUS = 5
MAGIC_COST, HEAVY_COST, POISON_COST = 8, 5, 4
HEAVY_MULT = 1.8


def hit_chance(luck):
    return max(0.0, min(1.0, (10 - luck) / 10))


def crit_chance(player_luck):
    return max(5, (10 - player_luck) * 3) / 100


def enemy_stats(layer, idx, p):
    scale = layer - 1
    post = max(0, layer - 5)
    hp = p["enemy_base_hp"] + p["enemy_scale_hp"] * scale
    atk = p["enemy_base_atk"] + p["enemy_scale_atk"] * scale
    dfn = p["enemy_base_def"] + p["enemy_scale_def"] * scale
    luck = 5
    if scale + 1 >= 4:
        luck = 3
    if post > 0:
        luck = 1
    is_boss = idx == 5
    if is_boss and layer == 5:
        hp, atk, dfn = 150, 100, 0
    elif is_boss:
        hp = hp + p["enemy_boss_hp"]
        atk = atk + p["enemy_boss_atk"]
        dfn = max(0, dfn - 5)
    if post == 0 and layer > 1 and not (is_boss and layer == 5):
        m = 1.0 + p["campaign_layer_growth"] * (layer - 1)
        hp, atk, dfn = round(hp * m), round(atk * m), round(dfn * m)
    if post > 0:
        hp = round(hp * p["enemy_endless_hp_growth"] ** post)
        atk = round(atk * p["enemy_endless_atk_growth"] ** post)
        dfn = round(dfn * p["enemy_endless_atk_growth"] ** post)
    return hp, atk, dfn, luck, is_boss


class Player:
    def __init__(self, atk_mult=1.0, hp_mult=1.0, gold_mult=1.0):
        self.maxhp = round(60 * hp_mult)
        self.hp = self.maxhp
        self.atk = round(25 * atk_mult)
        self.dfn = 10
        self.luck = 3
        self.maxmana = 20
        self.mana = 20
        self.level = 1
        self.gold = 0
        self.gold_mult = gold_mult
        self.owned = {}

    def avg_turn_damage(self, e_def):
        if self.mana >= MAGIC_COST:
            self.mana -= MAGIC_COST
            dmg = self.atk + MAGIC_BONUS
        elif self.mana >= POISON_COST:
            self.mana -= POISON_COST
            dmg = max(1, self.atk // 2 - e_def) + self.level * 2
        elif self.mana >= HEAVY_COST:
            self.mana -= HEAVY_COST
            base = max(1, round(self.atk * HEAVY_MULT) - e_def)
            dmg = hit_chance(self.luck) * base * (1 + crit_chance(self.luck))
        else:
            base = max(1, self.atk - e_def)
            dmg = hit_chance(self.luck) * base * (1 + crit_chance(self.luck))
        self.mana = min(self.maxmana, self.mana + MANA_REGEN)
        return dmg

    def levelup(self):
        pick = self.level % 3
        self.level += 1
        if pick == 0:
            self.maxhp += 20
            self.atk += 5
            self.dfn += 5
        elif pick == 1:
            self.atk += 10
            self.maxhp += 10
            self.dfn += 5
        else:
            self.dfn += 10
            self.atk += 5
            self.maxhp += 10
        self.maxmana += 5
        self.mana = self.maxmana
        self.hp = self.maxhp

    def shop(self, p):
        perms = [("wh", 40, "atk", 5), ("tw", 40, "dfn", 5), ("hv", 50, "hp", 15), ("lk", 60, "luck", 1)]
        growth = p["shop_price_growth"]
        for key, base, stat, amt in perms:
            n = self.owned.get(key, 0)
            price = round(base * growth ** n)
            if self.gold >= price:
                self.gold -= price
                self.owned[key] = n + 1
                if stat == "atk":
                    self.atk += amt
                elif stat == "dfn":
                    self.dfn += amt
                elif stat == "hp":
                    self.maxhp += amt
                    self.hp = self.maxhp
                elif stat == "luck":
                    self.luck = max(1, self.luck - 1)


def simulate(pacing, atk_mult=1.0, hp_mult=1.0, gold_mult=1.0, dmg_reduction=0.0,
             max_layer=40, verbose=False):
    player = Player(atk_mult, hp_mult, gold_mult)
    run_gold = 0
    total_turns = 0
    heal_pct = pacing["auto_battle_heal_threshold_percent"]
    gold_scale = pacing["gold_reward_scale"]
    shard_div = pacing["prestige_shard_divisor"]
    layer = 1
    while layer <= max_layer:
        layer_turns = 0
        for idx in range(1, 6):
            ehp, eatk, edef, eluck, _boss = enemy_stats(layer, idx, pacing)
            player.mana = min(player.maxmana, player.mana + 5)
            turns = 0
            while ehp > 0 and turns < 2000:
                if player.hp * 100 < heal_pct * player.maxhp:
                    player.hp = min(player.maxhp, player.hp + 10 * player.level)
                else:
                    ehp -= player.avg_turn_damage(edef)
                turns += 1
                if ehp <= 0:
                    break
                player.hp -= hit_chance(eluck) * max(0, eatk - player.dfn) * (1 - dmg_reduction)
                if player.hp <= 0:
                    return dict(
                        died_layer=layer, died_enemy=idx,
                        total_turns=total_turns + layer_turns + turns,
                        level=player.level, gold_earned=run_gold,
                        pending_shards=int(math.sqrt(run_gold / shard_div)),
                    )
            if turns >= 2000:
                return dict(
                    stuck_layer=layer, died_enemy=idx,
                    total_turns=total_turns + layer_turns + turns,
                    level=player.level, gold_earned=run_gold,
                    pending_shards=int(math.sqrt(run_gold / shard_div)),
                )
            layer_turns += turns
            gold = round(eatk * layer * gold_mult * gold_scale)
            player.gold += gold
            run_gold += gold
            if player.hp < player.maxhp * 0.5:
                player.hp = min(player.maxhp, player.hp + 10 * player.level)
        if verbose:
            print(f"  layer {layer:>2}: {layer_turns:>3} turns, atk {player.atk:>4}, "
                  f"hp {player.maxhp:>4}, gold {player.gold:>8}")
        total_turns += layer_turns
        player.levelup()
        player.shop(pacing)
        layer += 1
    return dict(
        cleared=max_layer, total_turns=total_turns, level=player.level,
        gold_earned=run_gold, pending_shards=int(math.sqrt(run_gold / shard_div)),
    )


def parse_args():
    parser = argparse.ArgumentParser(description="AshVault pacing simulator")
    parser.add_argument("--gold-scale", type=float, help="Override gold_reward_scale")
    parser.add_argument("--layer-growth", type=float, help="Override campaign_layer_growth")
    parser.add_argument("--scale-hp", type=int, help="Override enemy_scale_hp")
    parser.add_argument("--relic-chance", type=int, help="Override boss_relic_drop_percent")
    parser.add_argument("--max-layer", type=int, default=40)
    parser.add_argument("--campaign-only", action="store_true", help="Simulate layers 1-5 only")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    pacing = dict(PACING)
    if args.gold_scale is not None:
        pacing["gold_reward_scale"] = args.gold_scale
    if args.layer_growth is not None:
        pacing["campaign_layer_growth"] = args.layer_growth
    if args.scale_hp is not None:
        pacing["enemy_scale_hp"] = args.scale_hp
    if args.relic_chance is not None:
        pacing["boss_relic_drop_percent"] = args.relic_chance

    max_layer = 5 if args.campaign_only else args.max_layer

    print("=== Pacing knobs ===")
    for k, v in pacing.items():
        print(f"  {k}: {v}")
    print()

    print("=== Run (no prestige) ===")
    r = simulate(pacing, max_layer=max_layer, verbose=True)
    print(r)

    if not args.campaign_only:
        print("\n=== Campaign-only (layers 1-5) ===")
        print(simulate(pacing, max_layer=5))

        print("\n=== Prestige: Might×5, Fortune×5 ===")
        print(simulate(pacing, atk_mult=1.25, gold_mult=1.30, max_layer=5))
