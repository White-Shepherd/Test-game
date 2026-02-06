import random

from src.mythic_frontiers import CampaignGame, CombatResolver, Unit, create_default_templates, recruitable_units


def pick(name: str):
    return next(template for template in create_default_templates() if template.name == name)


def test_recruitable_units_follow_city_tier_and_race():
    templates = create_default_templates()
    tier_1 = recruitable_units(templates, 1, race="Aetherkin Concord")
    tier_3 = recruitable_units(templates, 3, race="Aetherkin Concord")

    assert len(tier_1) == 1
    assert len(tier_3) == 3


def test_flank_and_rear_increase_damage_relative_to_front():
    attacker = Unit(pick("Solar Mantle Wardens"))
    defender_a = Unit(pick("Burrowclaw Swarmers"))
    defender_b = Unit(pick("Burrowclaw Swarmers"))
    defender_c = Unit(pick("Burrowclaw Swarmers"))

    front = CombatResolver(random.Random(42)).resolve_attack(attacker, defender_a, position="front")
    flank = CombatResolver(random.Random(42)).resolve_attack(attacker, defender_b, position="flank")
    rear = CombatResolver(random.Random(42)).resolve_attack(attacker, defender_c, position="rear")

    assert flank["damage"] > front["damage"]
    assert rear["damage"] > flank["damage"]


def test_xp_can_grant_mythic_power_and_reputation():
    attacker = Unit(pick("Astral Seraphim"))
    defender = Unit(pick("Burrowclaw Swarmers"), health=12)

    resolver = CombatResolver(random.Random(1))
    resolver.resolve_attack(attacker, defender, position="rear")
    resolver.resolve_attack(attacker, defender, position="rear")

    assert attacker.mythic_power >= 1
    assert attacker.reputation >= 1


def test_city_upgrade_unlocks_new_recruits():
    game = CampaignGame(random.Random(0))
    empire = game.create_empire("Player", "Tempest Clans")

    base = recruitable_units(game.templates, empire.highest_city_tier, empire.race)
    game.upgrade_capital(empire)
    upgraded = recruitable_units(game.templates, empire.highest_city_tier, empire.race)

    assert len(base) == 1
    assert len(upgraded) == 2
