--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- PARSER FUNCTIONS

local function parse_breath_weapon(string_parenthetical, table_ability_information)
	local string_parenthetical_lower = string.lower(', ' .. string_parenthetical .. ',')
	local dice_damage, string_damage_type = string_parenthetical_lower:match(',%s(%d%d*d*d%d+)%s*(%l+)[.+]?')
	local string_save_type, number_save_dc = string_parenthetical_lower:match(',%s(%l*%l*%l*%l*%l*%l*%l*%l*)%s*dc%s*(%d+)[.+]?')
	if string_save_type == 'fort' then
		string_save_type = 'fortitude'
	end
	local dice_recharge = string_parenthetical_lower:match(',%susable%severy%s(%d%d*d*d%d+)%srounds[.+]?')

	table_ability_information['actions']['breathweapondmg']['damagelist']['primarydamage']['dice']['value'] = dice_damage
	table_ability_information['actions']['breathweapondmg']['damagelist']['primarydamage']['type']['value'] = string_damage_type
	if string_save_type and string_save_type ~= '' then
		table_ability_information['actions']['breathweaponsave']['savetype']['value'] = string_save_type
	end
	table_ability_information['actions']['breathweaponsave']['savedcmod']['value'] = number_save_dc
	table_ability_information['actions']['breathweaponsave']['onmissdamage']['value'] = 'half'
	if dice_recharge and dice_recharge ~= '' then
		if dice_recharge:sub(1, 2) == '1d' then
			dice_recharge = dice_recharge:gsub('1d', 'd')
		end
		table_ability_information['actions']['breathweaponrecharge']['durdice']['value'] = dice_recharge
	end
end

local function parse_bleed(string_parenthetical, table_ability_information)
	if string_parenthetical ~= '' then
		table_ability_information['actions']['zeffect-1']['label']['value'] =
			string.format(table_ability_information['actions']['zeffect-1']['label']['value'], string_parenthetical)
	end
end

-- ABILITY DEFINITIONS

-- luacheck: globals array_abilities
array_abilities = {
	-- luacheck: no max line length
	['Ancestral Enmity'] = {
		['name'] = 'Ancestral Enmity',
		['auto_add'] = true,
		['description'] = 'You gain a +2 bonus on melee attack rolls against dwarves and gnomes.  You may select this feat twice. Its effects stack.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['label'] = {
					['type'] = 'string',
					['value'] = 'Ancestral Enmity; IFT: TYPE(gnome); ATK: %d',
					['tiermultiplier'] = 2,
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
			['zeffect-2'] = {
				['label'] = {
					['type'] = 'string',
					['value'] = 'Ancestral Enmity; IFT: TYPE(dwarf); ATK: %d',
					['tiermultiplier'] = 2,
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Arcane Strike'] = {
		['name'] = 'Arcane Strike',
		['description'] = 'As a swift action, you can imbue your weapons with a fraction of your power. For 1 round, your weapons deal +1 damage and are treated as magic for the purpose of overcoming damage reduction. For every five caster levels you possess, this bonus increases by +1, to a maximum of +5 at 20th level.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['dmaxstat'] = { ['type'] = 'number', ['value'] = 4 },
				['durmod'] = { ['type'] = 'number', ['value'] = 1 },
				['durmult'] = { ['type'] = 'number', ['value'] = 0.25 },
				['durstat'] = { ['type'] = 'string', ['value'] = 'cl' },
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Arcane Strike; DMG: 1; DMGTYPE: magic' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Breath Weapon'] = {
		['name'] = 'Breath Weapon',
		['description'] = 'Some creatures can exhale a cloud, cone, or line of magical effects. A breath weapon usually deals damage and is often based on some type of energy. Breath weapons allow a Reflex save for half damage (DC = 10 + 1/2 breathing creature’s racial HD + breathing creature’s Constitution modifier; the exact DC is given in the creature’s descriptive text). A creature is immune to its own breath weapon unless otherwise noted. Some breath weapons allow a Fortitude save or a Will save instead of a Reflex save. Each breath weapon also includes notes on how often it can be used.',
		['string_ability_type'] = 'Special Abilities',
		['level'] = 0,
		['parser'] = parse_breath_weapon,
		['actions'] = {
			['breathweaponsave'] = {
				['onmissdamage'] = { ['type'] = 'string', ['value'] = nil },
				['srnotallowed'] = { ['type'] = 'number', ['value'] = 1 },
				['savedcmod'] = { ['type'] = 'number', ['value'] = nil },
				['savedctype'] = { ['type'] = 'string', ['value'] = 'fixed' },
				['savetype'] = { ['type'] = 'string', ['value'] = 'reflex' },
				['type'] = { ['type'] = 'string', ['value'] = 'cast' },
			},
			['breathweapondmg'] = {
				['damagelist'] = {
					['primarydamage'] = {
						['dice'] = { ['type'] = 'dice', ['value'] = nil },
						['type'] = { ['type'] = 'string', ['value'] = nil },
					},
				},
				['dmgnotspell'] = { ['type'] = 'number', ['value'] = 1 },
				['type'] = { ['type'] = 'string', ['value'] = 'damage' },
			},
			['breathweaponrecharge'] = {
				['durdice'] = { ['type'] = 'dice', ['value'] = 'd4' },
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Breath Weapon Recharge' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Bleed'] = {
		['name'] = 'Bleed',
		['description'] = 'A creature with this ability causes wounds that continue to bleed, dealing additional damage each round at the start of the affected creature’s turn. This bleeding can be stopped with a successful DC 15 Heal skill check or through the application of any magical healing. The amount of damage each round is specified in the creature’s entry.',
		['string_ability_type'] = 'Special Abilities',
		['level'] = 0,
		['parser'] = parse_bleed,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Bleed; DMGO: %s bleed' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Combat Expertise'] = {
		['name'] = 'Combat Expertise',
		['description'] = 'You can choose to take a -1 penalty on melee attack rolls and combat maneuver checks to gain a +1 dodge bonus to your Armor Class. When your base attack bonus reaches +4, and every +4 thereafter, the penalty increases by -1 and the dodge bonus increases by +1. You can only choose to use this feat when you declare that you are making an attack or a full-attack action with a melee weapon. The effects of this feat last until your next turn.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = {
					['type'] = 'string',
					['value'] = 'Combat Expertise; ATK: -1 [-QBAB] ,melee; AC: 1 [QBAB] dodge',
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Critical Focus'] = {
		['name'] = 'Critical Focus',
		['auto_add'] = true,
		['description'] = 'You receive a +4 circumstance bonus on attack rolls made to confirm critical hits.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Critical Focus; CC: +4 circumstance' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Deadly Aim'] = {
		['name'] = 'Deadly Aim',
		['description'] = 'You can choose to take a -1 penalty on all ranged attack rolls to gain a +2 bonus on all ranged damage rolls. When your base attack bonus reaches +4, and every +4 thereafter, the penalty increases by -1 and the bonus to damage increases by +2. You must choose to use this feat before making an attack roll and its effects last until your next turn. The bonus damage does not apply to touch attacks or effects that do not deal hit point damage.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = {
					['type'] = 'string',
					['value'] = 'Deadly Aim; ATK: -1 [-QBAB] ,ranged; DMG: 2 [QBAB] [QBAB] ,ranged',
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Defended Movement'] = {
		['name'] = 'Defended Movement',
		['auto_add'] = true,
		['description'] = 'You gain a +2 bonus to your AC against attacks of opportunity.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['durunit'] = { ['type'] = 'string', ['value'] = 'round' },
				['label'] = { ['type'] = 'string', ['value'] = 'Defended Movement; AC: 4 ,,opportunity' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Furious Focus'] = {
		['name'] = 'Furious Focus',
		['auto_add'] = true,
		['description'] = 'When you are wielding a two-handed weapon or a one-handed weapon with two hands, and using the Power Attack feat, you do not suffer Power Attack’s penalty on melee attack rolls on the first attack you make each turn. You still suffer the penalty on any additional attacks, including attacks of opportunity.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['apply'] = { ['type'] = 'string', ['value'] = 'roll' },
				['label'] = {
					['type'] = 'string',
					['value'] = 'Furious Focus; IF: CUSTOM(Power Attack 2-H); ATK: 1 [QBAB] ,melee',
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Mobility'] = {
		['name'] = 'Mobility',
		['auto_add'] = true,
		['description'] = 'You get a +4 dodge bonus to Armor Class against attacks of opportunity caused when you move out of or within a threatened area. A condition that makes you lose your Dexterity bonus to Armor Class (if any) also makes you lose dodge bonuses. Dodge bonuses stack with each other, unlike most types of bonuses.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['label'] = { ['type'] = 'string', ['value'] = 'Mobility; AC: 4 dodge,opportunity' },
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
	['Power Attack'] = {
		['name'] = 'Power Attack',
		['description'] = 'You can choose to take a -1 penalty on all melee attack rolls and combat maneuver checks to gain a +2 bonus on all melee damage rolls. This bonus to damage is increased by half (+50%) if you are making an attack with a two-handed weapon, a one handed weapon using two hands, or a primary natural weapon that adds 1-1/2 times your Strength modifier on damage rolls. This bonus to damage is halved (-50%) if you are making an attack with an off-hand weapon or secondary natural weapon. When your base attack bonus reaches +4, and every 4 points thereafter, the penalty increases by -1 and the bonus to damage increases by +2. You must choose to use this feat before making an attack roll, and its effects last until your next turn. The bonus damage does not apply to touch attacks or effects that do not deal hit point damage.',
		['string_ability_type'] = 'Feats',
		['level'] = 0,
		['actions'] = {
			['zeffect-1'] = {
				['label'] = {
					['type'] = 'string',
					['value'] = 'Power Attack 1-H; ATK: -1 [-QBAB] ,melee; DMG: 2 [QBAB] [QBAB] ,melee',
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
			['zeffect-2'] = {
				['label'] = {
					['type'] = 'string',
					['value'] = 'REMOVE: Power Attack 1-H; ATK: -1 [-QBAB] ,melee; DMG: 2 [QBAB] [QBAB] ,melee',
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
			['zeffect-3'] = {
				['label'] = {
					['type'] = 'string',
					['value'] = 'Power Attack 2-H; ATK: -1 [-QBAB] ,melee; DMG: 3 [QBAB] [QBAB] [QBAB] ,melee',
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
			['zeffect-4'] = {
				['label'] = {
					['type'] = 'string',
					['value'] = 'REMOVE: Power Attack 2-H; ATK: -1 [-QBAB] ,melee; DMG: 3 [QBAB] [QBAB] [QBAB] ,melee',
				},
				['targeting'] = { ['type'] = 'string', ['value'] = 'self' },
				['type'] = { ['type'] = 'string', ['value'] = 'effect' },
			},
		},
	},
}
