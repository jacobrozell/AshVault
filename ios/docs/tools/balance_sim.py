#!/usr/bin/env python3
"""Pacing simulator for AshVault.

Mirrors `Balance.swift` `// MARK: - Progression` and combat approximations.
Edit the PACING dict below when retuning — keep names aligned with Balance.swift.

Usage:
    python3 balance_sim.py                    # default tuning
    python3 balance_sim.py --campaign-only
    python3 balance_sim.py --offline --layer 6 --hours 4
    python3 balance_sim.py --gold-scale 0.45  # what-if gold
"""
import argparse
import math

# ── Sync with Balance.swift `// MARK: - Progression` ──────────────────────────
PACING = {
    "gold_reward_scale": 0.52,
    "shop_price_growth": 1.7,
    "mercenary_price_growth": 1.14,
    "prestige_shard_divisor": 100.0,
    "fortune_gold_per_level": 0.06,
    "enemies_per_layer": 7,
    "campaign_dragon_layer": 5,
    "enemy_base_hp": 50,
    "enemy_base_atk": 15,
    "enemy_base_def": 5,
    "enemy_scale_hp": 22,
    "enemy_scale_atk": 16,
    "enemy_scale_def": 6,
    "enemy_boss_hp": 20,
    "enemy_boss_atk": 10,
    "campaign_layer_growth": 0.06,
    "enemy_endless_hp_growth": 1.10,
    "enemy_endless_atk_growth": 1.06,
    "boss_relic_drop_percent": 18,
    "relic_duplicate_gold": 40,
    "auto_shop_max_mercenaries": 1,
    "auto_shop_max_sigil_scrolls": 1,
    "auto_battle_heal_threshold_percent": 35,
    "dragon_clear_shard_bonus": 3,
    "shard_bonus_per_layer": 1,
    "death_shard_retention": 0.35,
    "automation_unlock_shards": 6,
    # offline
    "base_offline_hours": 4.0,
    "base_offline_efficiency": 0.035,
    "manual_offline_efficiency": 0.020,
    "offline_merc_factor": 0.04,
    "offline_gold_cap_base": 2500,
    "offline_gold_cap_per_layer": 800,
}

MANA_REGEN = 2
EMBER_BOLT_BONUS = 5
EMBER_BOLT_COST, HEAVY_COST = 8, 5
HEAVY_MULT = 1.8


def hit_chance(luck):
    return max(0.0, min(1.0, (10 - luck) / 10))


def crit_chance(player_luck):
    return max(5, (10 - player_luck) * 3) / 100


def enemy_stats(layer, idx, p, scale_level=None):
    if scale_level is None:
        scale_level = layer - 1
    post = max(0, layer - p["campaign_dragon_layer"])
    hp = p["enemy_base_hp"] + p["enemy_scale_hp"] * scale_level
    atk = p["enemy_base_atk"] + p["enemy_scale_atk"] * scale_level
    dfn = p["enemy_base_def"] + p["enemy_scale_def"] * scale_level
    luck = 5
    if scale_level + 1 >= 4:
        luck = 3
    if post > 0:
        luck = 1
    is_boss = idx == p["enemies_per_layer"]
    if is_boss and layer == p["campaign_dragon_layer"]:
        hp, atk, dfn = 150, 100, 0
    elif is_boss:
        hp = hp + p["enemy_boss_hp"]
        atk = atk + p["enemy_boss_atk"]
        dfn = max(0, dfn - 5)
    if post == 0 and layer > 1 and not (is_boss and layer == p["campaign_dragon_layer"]):
        m = 1.0 + p["campaign_layer_growth"] * (layer - 1)
        hp, atk, dfn = round(hp * m), round(atk * m), round(dfn * m)
    if post > 0:
        hp = round(hp * p["enemy_endless_hp_growth"] ** post)
        atk = round(atk * p["enemy_endless_atk_growth"] ** post)
        dfn = round(dfn * p["enemy_endless_atk_growth"] ** post)
    lvl = 1 + scale_level
    return hp, atk, dfn, luck, is_boss, lvl


def offline_gold(p, layer, scale_level, attack, merc_dps, hours, auto=True, patience=0):
    hp, atk, _, _, _, lvl = enemy_stats(layer, 1, p, scale_level)
    cap_h = p["base_offline_hours"] + patience
    credited = min(hours, cap_h) * 3600
    rate = min(1.0, p["base_offline_efficiency"] + 0.05 * patience) if auto else p["manual_offline_efficiency"]
    hero = max(1, attack - (5 + 6 * scale_level))
    merc = merc_dps * p["offline_merc_factor"]
    gpk = max(1, round(atk * lvl * p["gold_reward_scale"]))
    gps = (hero + merc) / max(1, hp) * gpk
    raw = int(gps * credited * rate)
    cap = p["offline_gold_cap_base"] + p["offline_gold_cap_per_layer"] * max(1, layer)
    return dict(raw=raw, capped=min(raw, cap), gps=gps, hp=hp, gpk=gpk, gold_cap=cap)


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
        if self.mana >= EMBER_BOLT_COST:
            self.mana -= EMBER_BOLT_COST
            dmg = self.atk + EMBER_BOLT_BONUS
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


def crawl_shards(run_gold, layers_cleared, dragon_slain, p):
    gold_shards = int(math.sqrt(run_gold / p["prestige_shard_divisor"]))
    depth = layers_cleared * p["shard_bonus_per_layer"]
    if dragon_slain:
        depth += p["dragon_clear_shard_bonus"]
    return gold_shards, depth, gold_shards + depth


def simulate(pacing, atk_mult=1.0, hp_mult=1.0, gold_mult=1.0, dmg_reduction=0.0,
             max_layer=40, verbose=False):
    player = Player(atk_mult, hp_mult, gold_mult)
    run_gold = 0
    total_turns = 0
    layers_cleared = 0
    dragon_slain = False
    heal_pct = pacing["auto_battle_heal_threshold_percent"]
    gold_scale = pacing["gold_reward_scale"]
    enemies = pacing["enemies_per_layer"]
    layer = 1
    while layer <= max_layer:
        layer_turns = 0
        for idx in range(1, enemies + 1):
            ehp, eatk, edef, eluck, _boss, lvl = enemy_stats(layer, idx, pacing)
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
                    gs, ds, total = crawl_shards(run_gold, layers_cleared, dragon_slain, pacing)
                    return dict(
                        died_layer=layer, died_enemy=idx,
                        total_turns=total_turns + layer_turns + turns,
                        level=player.level, gold_earned=run_gold,
                        gold_shards=gs, depth_bonus=ds, pending_shards=total,
                        death_salvaged=int(total * pacing["death_shard_retention"]),
                    )
            if turns >= 2000:
                return dict(stuck_layer=layer, died_enemy=idx, total_turns=total_turns + layer_turns + turns)
            layer_turns += turns
            gold = round(eatk * lvl * gold_mult * gold_scale)
            player.gold += gold
            run_gold += gold
            if player.hp < player.maxhp * 0.5:
                player.hp = min(player.maxhp, player.hp + 10 * player.level)
        if verbose:
            print(f"  layer {layer:>2}: {layer_turns:>3} turns, atk {player.atk:>4}, "
                  f"hp {player.maxhp:>4}, gold {player.gold:>8}")
        total_turns += layer_turns
        layers_cleared += 1
        if layer == pacing["campaign_dragon_layer"]:
            dragon_slain = True
        player.levelup()
        player.shop(pacing)
        layer += 1
    gs, ds, total = crawl_shards(run_gold, layers_cleared, dragon_slain, pacing)
    return dict(
        cleared=max_layer, total_turns=total_turns, level=player.level,
        gold_earned=run_gold, gold_shards=gs, depth_bonus=ds, pending_shards=total,
    )


def parse_args():
    parser = argparse.ArgumentParser(description="AshVault pacing simulator")
    parser.add_argument("--gold-scale", type=float, help="Override gold_reward_scale")
    parser.add_argument("--layer-growth", type=float, help="Override campaign_layer_growth")
    parser.add_argument("--scale-hp", type=int, help="Override enemy_scale_hp")
    parser.add_argument("--max-layer", type=int, default=40)
    parser.add_argument("--campaign-only", action="store_true")
    parser.add_argument("--offline", action="store_true", help="Estimate offline payout")
    parser.add_argument("--layer", type=int, default=6)
    parser.add_argument("--scale", type=int, default=5)
    parser.add_argument("--attack", type=int, default=85)
    parser.add_argument("--merc-dps", type=int, default=120)
    parser.add_argument("--hours", type=float, default=4.0)
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    pacing = dict(PACING)
    if args.gold_scale is not None:
        pacing["gold_reward_scale"] = args.gold_scale

    if args.offline:
        r = offline_gold(pacing, args.layer, args.scale, args.attack, args.merc_dps, args.hours)
        print("=== Offline estimate ===")
        print(f"  layer={args.layer} scale={args.scale} attack={args.attack} mercDPS={args.merc_dps}")
        print(f"  {args.hours}h away → raw {r['raw']:,}g, capped {r['capped']:,}g (cap {r['gold_cap']:,})")
        raise SystemExit(0)

    max_layer = pacing["campaign_dragon_layer"] if args.campaign_only else args.max_layer

    print("=== Pacing knobs ===")
    for k, v in pacing.items():
        print(f"  {k}: {v}")
    print()

    print("=== Run (no prestige) ===")
    r = simulate(pacing, max_layer=max_layer, verbose=True)
    print(r)

    if not args.campaign_only:
        print("\n=== Campaign-only ===")
        print(simulate(pacing, max_layer=pacing["campaign_dragon_layer"]))

        print("\n=== Offline L6 post-dragon (4h) ===")
        print(offline_gold(pacing, 6, 5, 85, 120, 4.0))
