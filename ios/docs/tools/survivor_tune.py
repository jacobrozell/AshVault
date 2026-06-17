#!/usr/bin/env python3
"""Quick survivor-crawl pacing sweep (mirrors Balance.swift survivor knobs).

Usage:
    python3 ios/docs/tools/survivor_tune.py
    python3 ios/docs/tools/survivor_tune.py --auto-dmg 0.95 --layer-growth 0.04
"""
import argparse

P = dict(
    enemies_per_layer=8,
    vault_heart_layer=10,
    kills_per_draft_base=4,
    kills_per_draft_min=3,
    draft_attack=10,
    draft_defense=8,
    draft_hp=30,
    manual_dmg=1.20,
    auto_dmg=0.80,
    gold_reward_scale=0.52,
    enemy_base_hp=50,
    enemy_base_atk=15,
    enemy_base_def=5,
    enemy_scale_hp=23,
    enemy_scale_atk=13,
    enemy_scale_def=6,
    enemy_boss_hp=20,
    enemy_boss_atk=10,
    campaign_layer_growth=0.05,
    auto_heal_threshold=35,
    auto_camp_every=1,
    vault_heart_bonus=5,
    vault_heart_hp=140,
    vault_heart_atk=90,
)


def hit_chance(luck):
    return max(0.0, min(1.0, (10 - luck) / 10))


def enemy_stats(layer, idx, p):
    scale = layer - 1
    hp = p["enemy_base_hp"] + p["enemy_scale_hp"] * scale
    atk = p["enemy_base_atk"] + p["enemy_scale_atk"] * scale
    dfn = p["enemy_base_def"] + p["enemy_scale_def"] * scale
    luck = 3 if scale + 1 >= 4 else 5
    is_boss = idx == p["enemies_per_layer"]
    if is_boss and layer == p["vault_heart_layer"]:
        hp, atk, dfn = p["vault_heart_hp"], p["vault_heart_atk"], 0
    elif is_boss:
        hp += p["enemy_boss_hp"]
        atk += p["enemy_boss_atk"]
        dfn = max(0, dfn - 5)
    if layer > 1 and not (is_boss and layer == p["vault_heart_layer"]):
        m = 1.0 + p["campaign_layer_growth"] * (layer - 1)
        hp, atk, dfn = round(hp * m), round(atk * m), round(dfn * m)
    return hp, atk, dfn, luck, is_boss


def draft_every_kills(ring):
    return max(P["kills_per_draft_min"],
               P["kills_per_draft_base"] - (ring - 1) // 2)


def simulate(p, auto=True, verbose=False):
    atk, dfn, maxhp = 25, 10, 60
    hp, level = maxhp, 1
    gold = run_gold = 0
    kills_since_draft = boss_kills = layers_cleared = 0
    ticks = 0
    layer_ticks = {}

    for layer in range(1, p["vault_heart_layer"] + 1):
        layer_start = ticks
        for idx in range(1, p["enemies_per_layer"] + 1):
            ehp, eatk, edef, eluck, is_boss = enemy_stats(layer, idx, p)
            dmg_mult = p["auto_dmg"] if auto else p["manual_dmg"]
            while ehp > 0:
                ticks += 1
                if hp * 100 < p["auto_heal_threshold"] * maxhp:
                    hp = min(maxhp, hp + 10 * level)
                else:
                    raw = max(1, int(atk * dmg_mult) - edef)
                    ehp -= hit_chance(3) * raw
                if ehp <= 0:
                    break
                hp -= int(hit_chance(eluck) * max(0, eatk - dfn))
                if hp <= 0:
                    return dict(died_layer=layer, died_idx=idx, ticks=ticks, gold=run_gold)
            gold += max(1, int(eatk * level * p["gold_reward_scale"]))
            run_gold = gold
            if not is_boss:
                kills_since_draft += 1
                if kills_since_draft >= draft_every_kills(layer):
                    kills_since_draft = 0
                    level += 1
                    atk += p["draft_attack"]
                    dfn += p["draft_defense"]
                    maxhp += p["draft_hp"]
                    hp = maxhp
            else:
                boss_kills += 1
                layers_cleared += 1
                if layers_cleared % p["auto_camp_every"] == 0 or hp < maxhp * 0.6:
                    if gold >= 40:
                        gold -= 40
                        atk += 5
                    if gold >= 50:
                        gold -= 50
                        maxhp += 15
                        hp = maxhp
        layer_ticks[layer] = ticks - layer_start
        if verbose:
            print(f"  ring {layer:>2}: {layer_ticks[layer]:>4}s  atk={atk} hp={maxhp}")

    depth = layer // 2 + boss_kills + p["vault_heart_bonus"]
    return dict(cleared=True, ticks=ticks, minutes=round(ticks / 60, 1),
                gold=run_gold, pending_shards=depth, layer_ticks=layer_ticks,
                final_atk=atk, final_maxhp=maxhp)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--auto-dmg", type=float)
    ap.add_argument("--layer-growth", type=float)
    ap.add_argument("--manual", action="store_true")
    args = ap.parse_args()
    if args.auto_dmg is not None:
        P["auto_dmg"] = args.auto_dmg
    if args.layer_growth is not None:
        P["campaign_layer_growth"] = args.layer_growth

    print("=== Survivor crawl estimate (1 tick ≈ 1 sec) ===")
    for label, auto in [("auto-battle", True), ("manual", False)]:
        r = simulate(P, auto=auto, verbose=(auto and not args.manual))
        print(f"\n{label}:")
        if r.get("cleared"):
            print(f"  Vault Heart in {r['ticks']}s (~{r['minutes']} min)  "
                  f"gold={r['gold']:,}  shards={r['pending_shards']}")
        else:
            print(f"  DIED ring {r['died_layer']} after {r['ticks']}s (~{r['ticks']//60} min)")
