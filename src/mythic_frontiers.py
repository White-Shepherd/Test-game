from __future__ import annotations

from dataclasses import dataclass, field
import random
from typing import Dict, List


@dataclass(frozen=True)
class UnitTemplate:
    race: str
    name: str
    tier_required: int
    attack: int
    defense: int
    weapon_damage: int


@dataclass
class Unit:
    template: UnitTemplate
    xp: int = 0
    mythic_power: int = 0
    reputation: int = 0
    health: int = 25

    def gain_xp(self, amount: int) -> None:
        self.xp += amount
        while self.xp >= self.next_rank_threshold:
            self.xp -= self.next_rank_threshold
            self.mythic_power += 1
            self.reputation += 1

    @property
    def next_rank_threshold(self) -> int:
        return 6 + (self.mythic_power * 2)


@dataclass
class City:
    name: str
    tier: int = 1

    @property
    def empire_attack_bonus(self) -> int:
        return max(0, self.tier - 1)

    @property
    def empire_defense_bonus(self) -> int:
        return max(0, self.tier - 1)

    def upgrade(self) -> bool:
        if self.tier < 3:
            self.tier += 1
            return True
        return False


@dataclass
class Empire:
    name: str
    race: str
    cities: List[City] = field(default_factory=list)
    treasury: int = 120

    @property
    def highest_city_tier(self) -> int:
        return max((city.tier for city in self.cities), default=1)

    @property
    def attack_bonus(self) -> int:
        return sum(city.empire_attack_bonus for city in self.cities)

    @property
    def defense_bonus(self) -> int:
        return sum(city.empire_defense_bonus for city in self.cities)


def create_default_templates() -> List[UnitTemplate]:
    return [
        UnitTemplate("Aetherkin Concord", "Starborne Spearhost", 1, 4, 3, 2),
        UnitTemplate("Aetherkin Concord", "Solar Mantle Wardens", 2, 6, 5, 2),
        UnitTemplate("Aetherkin Concord", "Astral Seraphim", 3, 8, 6, 3),
        UnitTemplate("Chthonic Brood", "Burrowclaw Swarmers", 1, 5, 2, 2),
        UnitTemplate("Chthonic Brood", "Sporehorn Ravagers", 2, 7, 4, 3),
        UnitTemplate("Chthonic Brood", "Eclipse Carapace Titans", 3, 9, 7, 3),
        UnitTemplate("Tempest Clans", "Stormrider Reavers", 1, 4, 3, 2),
        UnitTemplate("Tempest Clans", "Thunder Totem Guard", 2, 6, 5, 2),
        UnitTemplate("Tempest Clans", "Skyfang Mythhunters", 3, 8, 5, 4),
    ]


def recruitable_units(templates: List[UnitTemplate], city_tier: int, race: str | None = None) -> List[UnitTemplate]:
    return [
        template
        for template in templates
        if template.tier_required <= city_tier and (race is None or template.race == race)
    ]


class CombatResolver:
    POSITION_BONUS = {"front": 0, "flank": 2, "rear": 4}

    def __init__(self, rng: random.Random | None = None):
        self.rng = rng or random.Random()

    def roll_d6(self) -> int:
        return self.rng.randint(1, 6)

    def resolve_attack(
        self,
        attacker: Unit,
        defender: Unit,
        position: str = "front",
        attacker_empire_bonus: int = 0,
        defender_empire_bonus: int = 0,
    ) -> Dict[str, int]:
        if position not in self.POSITION_BONUS:
            raise ValueError(f"Unknown position '{position}'.")

        attack_roll = self.roll_d6()
        defense_roll = self.roll_d6()

        attack_power = (
            attacker.template.attack
            + attack_roll
            + attacker.mythic_power
            + attacker_empire_bonus
            + self.POSITION_BONUS[position]
        )
        defense_power = defender.template.defense + defense_roll + defender_empire_bonus

        damage = max(1, attack_power - defense_power + attacker.template.weapon_damage)
        defender.health = max(0, defender.health - damage)

        attacker.gain_xp(2)
        if defender.health == 0:
            attacker.gain_xp(3)

        return {
            "attack_roll": attack_roll,
            "defense_roll": defense_roll,
            "attack_power": attack_power,
            "defense_power": defense_power,
            "damage": damage,
            "defender_health": defender.health,
        }


class CampaignGame:
    UPGRADE_COST = 40
    RECRUIT_COST = 35
    LAND_DEVELOP_YIELD = 25

    def __init__(self, rng: random.Random | None = None):
        self.rng = rng or random.Random()
        self.templates = create_default_templates()
        self.resolver = CombatResolver(self.rng)

    def create_empire(self, name: str, race: str) -> Empire:
        return Empire(name=name, race=race, cities=[City("Capital", tier=1)], treasury=120)

    def recruit_unit(self, empire: Empire, unit_name: str) -> Unit:
        available = recruitable_units(self.templates, empire.highest_city_tier, empire.race)
        chosen = next((u for u in available if u.name == unit_name), None)
        if chosen is None:
            raise ValueError("Unit not unlocked for this empire.")
        if empire.treasury < self.RECRUIT_COST:
            raise ValueError("Not enough treasury to recruit.")
        empire.treasury -= self.RECRUIT_COST
        return Unit(chosen)

    def develop_land(self, empire: Empire) -> None:
        empire.treasury += self.LAND_DEVELOP_YIELD

    def upgrade_capital(self, empire: Empire) -> bool:
        if empire.treasury < self.UPGRADE_COST:
            return False
        upgraded = empire.cities[0].upgrade()
        if upgraded:
            empire.treasury -= self.UPGRADE_COST
        return upgraded

    def quick_battle(self, player: Unit, enemy: Unit, player_empire: Empire, enemy_empire: Empire, position: str) -> str:
        while player.health > 0 and enemy.health > 0:
            self.resolver.resolve_attack(
                player,
                enemy,
                position=position,
                attacker_empire_bonus=player_empire.attack_bonus,
                defender_empire_bonus=enemy_empire.defense_bonus,
            )
            if enemy.health == 0:
                return "player"
            self.resolver.resolve_attack(
                enemy,
                player,
                position="front",
                attacker_empire_bonus=enemy_empire.attack_bonus,
                defender_empire_bonus=player_empire.defense_bonus,
            )
        return "enemy"


class MythicFrontiersGUI:
    def __init__(self):
        import tkinter as tk
        from tkinter import ttk

        self.tk = tk
        self.ttk = ttk
        self.game = CampaignGame()
        self.races = sorted({t.race for t in self.game.templates})

        self.root = tk.Tk()
        self.root.title("Mythic Frontiers Launcher")
        self.root.geometry("430x240")

        self._build_launcher_ui()

    def _build_launcher_ui(self) -> None:
        frame = self.ttk.Frame(self.root, padding=16)
        frame.pack(fill="both", expand=True)

        self.ttk.Label(frame, text="Mythic Frontiers", font=("Arial", 16, "bold")).pack(pady=4)
        self.ttk.Label(frame, text="Pick your race, then click Launch Game Window.").pack(pady=4)

        self.race_var = self.tk.StringVar(value=self.races[0])
        self.ttk.Label(frame, text="Starting Race").pack(pady=(8, 0))
        self.ttk.Combobox(frame, textvariable=self.race_var, values=self.races, state="readonly").pack()

        self.ttk.Button(frame, text="Launch Game Window", command=self.launch_game_window).pack(pady=16)

    def launch_game_window(self) -> None:
        player_race = self.race_var.get()
        enemy_race = next(r for r in self.races if r != player_race)

        self.player = self.game.create_empire("Player Dominion", player_race)
        self.enemy = self.game.create_empire("Rival Host", enemy_race)

        self.game_window = self.tk.Toplevel(self.root)
        self.game_window.title("Mythic Frontiers Campaign")
        self.game_window.geometry("640x420")

        top = self.ttk.Frame(self.game_window, padding=12)
        top.pack(fill="x")
        self.status_label = self.ttk.Label(top, text="")
        self.status_label.pack(anchor="w")

        buttons = self.ttk.Frame(self.game_window, padding=12)
        buttons.pack(fill="x")
        self.ttk.Button(buttons, text="Develop Land", command=self.on_develop).pack(side="left", padx=4)
        self.ttk.Button(buttons, text="Upgrade City", command=self.on_upgrade).pack(side="left", padx=4)

        self.unit_var = self.tk.StringVar()
        self.position_var = self.tk.StringVar(value="front")

        battle_controls = self.ttk.Frame(self.game_window, padding=12)
        battle_controls.pack(fill="x")
        self.ttk.Label(battle_controls, text="Unit:").pack(side="left")
        self.unit_combo = self.ttk.Combobox(battle_controls, textvariable=self.unit_var, state="readonly", width=26)
        self.unit_combo.pack(side="left", padx=4)

        self.ttk.Label(battle_controls, text="Angle:").pack(side="left")
        self.ttk.Combobox(
            battle_controls,
            textvariable=self.position_var,
            values=list(CombatResolver.POSITION_BONUS.keys()),
            state="readonly",
            width=8,
        ).pack(side="left", padx=4)

        self.ttk.Button(battle_controls, text="Fight Battle", command=self.on_battle).pack(side="left", padx=8)

        log_frame = self.ttk.Frame(self.game_window, padding=(12, 0, 12, 12))
        log_frame.pack(fill="both", expand=True)
        self.log_text = self.tk.Text(log_frame, height=14, wrap="word")
        self.log_text.pack(fill="both", expand=True)

        self.refresh_ui()
        self.log("Game window launched. Begin expanding your mythic empire.")

    def refresh_ui(self) -> None:
        self.status_label.configure(
            text=(
                f"Race: {self.player.race} | Capital Tier: {self.player.highest_city_tier} | "
                f"Treasury: {self.player.treasury}"
            )
        )

        options = recruitable_units(self.game.templates, self.player.highest_city_tier, self.player.race)
        names = [u.name for u in options]
        self.unit_combo["values"] = names
        if names and self.unit_var.get() not in names:
            self.unit_var.set(names[0])

    def log(self, message: str) -> None:
        self.log_text.insert("end", message + "\n")
        self.log_text.see("end")

    def on_develop(self) -> None:
        self.game.develop_land(self.player)
        self.refresh_ui()
        self.log(f"Land developed. +{self.game.LAND_DEVELOP_YIELD} treasury.")

    def on_upgrade(self) -> None:
        if self.game.upgrade_capital(self.player):
            self.log("Capital upgraded! New unit tier unlocked.")
        else:
            self.log("Upgrade failed (max tier reached or insufficient treasury).")
        self.refresh_ui()

    def on_battle(self) -> None:
        selected = self.unit_var.get()
        if not selected:
            self.log("No unit available to recruit.")
            return

        try:
            player_unit = self.game.recruit_unit(self.player, selected)
        except ValueError as error:
            self.log(str(error))
            self.refresh_ui()
            return

        enemy_options = recruitable_units(self.game.templates, self.enemy.highest_city_tier, self.enemy.race)
        enemy_unit = Unit(self.game.rng.choice(enemy_options))
        angle = self.position_var.get() if self.position_var.get() in CombatResolver.POSITION_BONUS else "front"

        winner = self.game.quick_battle(player_unit, enemy_unit, self.player, self.enemy, angle)
        if winner == "player":
            spoils = 50 + (player_unit.reputation * 5)
            self.player.treasury += spoils
            self.log(
                f"Victory with {player_unit.template.name}! Angle={angle}. Spoils +{spoils}. "
                f"Reputation={player_unit.reputation}."
            )
        else:
            self.log(f"Defeat with {player_unit.template.name}. Regroup and build stronger armies.")

        self.refresh_ui()

    def run(self) -> None:
        self.root.mainloop()


def run_cli_game() -> None:
    game = CampaignGame()
    races = sorted({t.race for t in game.templates})

    print("=== Mythic Frontiers: Playable CLI Prototype ===")
    print("Choose your race:")
    for idx, race in enumerate(races, start=1):
        print(f"  {idx}. {race}")

    race_choice = int(input("Race number: ").strip())
    player_race = races[race_choice - 1]

    player = game.create_empire("Player Dominion", player_race)
    enemy_race = next(r for r in races if r != player_race)
    enemy = game.create_empire("Rival Host", enemy_race)

    while True:
        print("\n--- Empire Status ---")
        print(f"Race: {player.race}")
        print(f"Capital Tier: {player.highest_city_tier}")
        print(f"Treasury: {player.treasury}")
        print("Actions: 1) Develop land  2) Upgrade city  3) Battle  4) Quit")

        choice = input("Action: ").strip()
        if choice == "1":
            game.develop_land(player)
            print(f"Land developed. Treasury +{game.LAND_DEVELOP_YIELD}.")
        elif choice == "2":
            if game.upgrade_capital(player):
                print("Capital upgraded! New units unlocked.")
            else:
                print("Upgrade unavailable (max tier or insufficient treasury).")
        elif choice == "3":
            options = recruitable_units(game.templates, player.highest_city_tier, player.race)
            print("Recruit which unit for battle?")
            for idx, template in enumerate(options, start=1):
                print(f"  {idx}. {template.name} (Tier {template.tier_required})")
            unit_idx = int(input("Unit number: ").strip())
            player_unit = game.recruit_unit(player, options[unit_idx - 1].name)

            enemy_options = recruitable_units(game.templates, enemy.highest_city_tier, enemy.race)
            enemy_unit = Unit(game.rng.choice(enemy_options))

            position = input("Engagement angle (front/flank/rear): ").strip().lower() or "front"
            if position not in CombatResolver.POSITION_BONUS:
                position = "front"

            winner = game.quick_battle(player_unit, enemy_unit, player, enemy, position)
            if winner == "player":
                spoils = 50 + (player_unit.reputation * 5)
                player.treasury += spoils
                print(f"Victory! Spoils gained: {spoils}. Unit reputation: {player_unit.reputation}")
            else:
                print("Defeat. Regroup and expand your empire.")
        elif choice == "4":
            print("Campaign ended.")
            return
        else:
            print("Unknown action.")


def run_demo() -> None:
    templates = create_default_templates()
    player_empire = Empire("Player Dominion", race="Aetherkin Concord", cities=[City("Eidolon Prime", tier=2)])
    enemy_empire = Empire("Rival Brood", race="Chthonic Brood", cities=[City("Maw Hive", tier=1)])

    player_template = next(t for t in templates if t.name == "Solar Mantle Wardens")
    enemy_template = next(t for t in templates if t.name == "Burrowclaw Swarmers")

    attacker = Unit(player_template)
    defender = Unit(enemy_template)

    resolver = CombatResolver()
    result = resolver.resolve_attack(
        attacker,
        defender,
        position="flank",
        attacker_empire_bonus=player_empire.attack_bonus,
        defender_empire_bonus=enemy_empire.defense_bonus,
    )

    print("=== Mythic Frontiers Combat Demo ===")
    print(f"Attacker: {attacker.template.name} ({attacker.template.race})")
    print(f"Defender: {defender.template.name} ({defender.template.race})")
    print(f"Result: {result}")
    print(
        "Attacker progression -> "
        f"Mythic Power: {attacker.mythic_power}, Reputation: {attacker.reputation}, XP bank: {attacker.xp}"
    )


def run_gui_game() -> None:
    try:
        app = MythicFrontiersGUI()
    except Exception as error:
        print(f"GUI unavailable ({error}). Falling back to CLI mode.")
        run_cli_game()
        return
    app.run()


if __name__ == "__main__":
    run_gui_game()
