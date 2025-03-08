--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals array_modules
-- Modules to check for spells
array_modules = {
	['SpellbookExtended'] = { ['name'] = '@PFRPG - Spellbook Extended', ['prefix'] = 'spelldesc.' },
	['Spellbook'] = { ['name'] = '@PFRPG - Spellbook', ['prefix'] = 'spelldesc.' },
}

--
--	SPELL ACTION REPLACEMENT FUNCTIONS
--
local function trim_spell_name(string_spell_name)
	local tFormats = { ['Greater'] = false, ['Lesser'] = false, ['Communal'] = false, ['Mass'] = false }
	local tTrims = { ['Maximized'] = false, ['Heightened'] = false, ['Empowered'] = false, ['Quickened'] = false }

	local string_spell_name_lower = string_spell_name:lower()
	-- remove tags from spell name
	for s, _ in pairs(tFormats) do
		local nS, nE = string_spell_name_lower:find(s:lower())
		if nS and nE then
			string_spell_name = string_spell_name:sub(0, nS - 1) .. string_spell_name:sub(nE + 1, string_spell_name:len())
			tFormats[s] = true
		end
	end
	for s, _ in pairs(tTrims) do
		local nS, nE = string_spell_name_lower:find(s:lower())
		if nS and nE then
			string_spell_name = string_spell_name:sub(0, nS - 1) .. string_spell_name:sub(nE + 1, string_spell_name:len())
			tTrims[s] = true
		end
	end

	-- remove certain sets of characters
	--string_spell_name = string_spell_name:gsub("%u%u%u%u", "")
	--string_spell_name = string_spell_name:gsub("%u%u%u", "")
	string_spell_name = string_spell_name:gsub('AP%d+', '')
	--string_spell_name = string_spell_name:gsub("%u%u", "")
	string_spell_name = string_spell_name:gsub('.+:', '')
	string_spell_name = string_spell_name:gsub(',.+', '')
	string_spell_name = string_spell_name:gsub('%[.-%]', '')
	string_spell_name = string_spell_name:gsub('%(.-%)', '')
	string_spell_name = string_spell_name:gsub('%A+', '')

	-- remove uppercase D or M at end of name
	local number_name_end = string.find(string_spell_name, 'D', string.len(string_spell_name))
		or string.find(string_spell_name, 'M', string.len(string_spell_name))
	if number_name_end then
		string_spell_name = string_spell_name:sub(1, number_name_end - 1)
	end

	-- convert to lower-case
	string_spell_name_lower = string_spell_name:lower()

	-- append relevant tags to end of spell name
	for s, v in pairs(tFormats) do
		if v == true then
			string_spell_name_lower = string.format('%s%s', string_spell_name_lower, s:lower())
		end
	end

	return string_spell_name_lower, tTrims['Maximized'], tTrims['Empowered']
end

local function replace_action_nodes(node_spell, node_reference_spell, is_maximized, is_empowered)
	if not node_reference_spell then
		return
	end

	local node_reference_actions = DB.getChild(node_reference_spell, 'actions')
	if not node_reference_actions then
		return
	end

	local node_actions = DB.createChild(node_spell, 'actions')
	DB.deleteChildren(node_actions)
	for _, node_reference_action in ipairs(DB.getChildList(node_reference_actions)) do
		DB.copyNode(node_reference_action, DB.createChild(node_actions, DB.getName(node_reference_action)))
	end

	local node_spell_new_damage = DB.getChild(node_actions, 'damage')
	if not node_spell_new_damage then
		return
	end

	-- set up metamagic if applicable
	if is_empowered then
		DB.setValue(node_spell_new_damage, 'meta', 'string', 'empower')
	end
	if is_maximized then
		DB.setValue(node_spell_new_damage, 'meta', 'string', 'maximize')
	end
end

local function add_spell_description(node_spell, node_reference_spell)
	if not node_reference_spell or not node_spell or type(node_spell) ~= 'databasenode' then
		return
	end
	local sOrigSpellDesc = DB.getValue(node_spell, 'description', '')
	if sOrigSpellDesc ~= '' and sOrigSpellDesc ~= '<p></p>' then
		return
	end

	DB.deleteChild(node_spell, 'description')
	local string_full_description = DB.getValue(node_reference_spell, 'description', '<p></p>')
	DB.setValue(node_spell, 'description_full', 'formattedtext', string_full_description)
	DB.setValue(node_spell, 'description', 'formattedtext', string_full_description)
	SpellManager.convertSpellDescToString(node_spell)
end

local function add_spell_information(node_spell, node_reference_spell)
	if not node_reference_spell or not node_spell then
		return
	end

	for _, node_reference_spell_subnode in ipairs(DB.getChildList(node_reference_spell)) do
		local string_node_name = DB.getName(node_reference_spell_subnode)
		if string_node_name ~= 'description' and string_node_name ~= 'name' then
			if not DB.getChild(node_spell, string_node_name) then
				local string_node_type = DB.getType(node_reference_spell_subnode)
				local node_spell_subnode = DB.createChild(node_spell, string_node_name, string_node_type)
				DB.copyNode(node_reference_spell_subnode, node_spell_subnode)
			end
		end
	end
end

local function find_reference_spell(string_spell_name)
	for _, table_module_data in pairs(array_modules) do
		local node_reference_spell = DB.findNode(table_module_data['prefix'] .. string_spell_name .. table_module_data['name'])
		if node_reference_spell then
			return node_reference_spell
		end
	end
end

local function replace_spell_actions(node_spell)
	local string_spell_name, is_maximized, is_empowered = trim_spell_name(DB.getValue(node_spell, 'name', ''))

	--Debug.chat(type(node_spell))
	local node_reference_spell = find_reference_spell(string_spell_name)
	--Debug.chat(node_reference_spell, type(node_reference_spell))
	if not node_reference_spell then
		return
	end

	replace_action_nodes(node_spell, node_reference_spell, is_maximized, is_empowered)
	add_spell_description(node_spell, node_reference_spell)
	add_spell_information(node_spell, node_reference_spell)

	return node_reference_spell
end

local function find_spell_nodes(nodeEntry)
	for _, nodeSpellset in ipairs(DB.getChildList(nodeEntry, 'spellset')) do
		for _, nodeSpellLevel in ipairs(DB.getChildList(nodeSpellset, 'levels')) do
			for _, nodeSpell in ipairs(DB.getChildList(nodeSpellLevel, 'spells')) do
				--Debug.chat(type(nodeSpell))
				if DB.getType(nodeSpell) == 'node' and type(nodeSpell) ~= 'error' then
					local sSpellName = DB.getValue(nodeSpell, 'name', '')
					if not string.find(sSpellName, '[LOCK]') and not string.match(sSpellName, '%(Mythic.*%)') then
						replace_spell_actions(nodeSpell)
					end
					--Debug.console('nodeSpell', nodeSpell)
					--else
					--Debug.console('nodeSpell', nodeSpell)
					--Debug.console('nodeSpell.getType', DB.getType(nodeSpell))
					--Debug.console('nodeSpell.getValue', DB.getValue(nodeSpell))
				end
			end
		end
	end
end

--
--	MALADY LINKING FUNCTIONS
--

---	This function converts a string of values separated by semicolons to a table
--	@param s input, a string of values separated by semicolons
--	@return t output, an indexed table of values
local function string_to_table(string_input)
	if not string_input or string_input == '' then
		return {}
	end

	string_input = string_input .. ';' -- ending semicolon
	local table_output = {} -- table to collect fields
	local number_field_start = 1
	repeat
		local number_nexti = string.find(string_input, ';', number_field_start)
		table.insert(table_output, string.sub(string_input, number_field_start, number_nexti - 1))
		number_field_start = number_nexti + 1
	until number_field_start > string.len(string_input)

	return table_output
end

---	This function adds a link to matching creature maladies.
--	To work, it needs the malady node and npc node.
local function add_malady_link(node_malady, node_npc)
	local table_malady_npcs = string_to_table(DB.getValue(node_malady, 'npc')) or {}
	if table_malady_npcs ~= {} then
		for _, string_malady_linked_npc in pairs(table_malady_npcs) do
			local string_difficulty_class = (string_malady_linked_npc:match(' %(DC %d+%)')) or ''
			string_malady_linked_npc = string_malady_linked_npc:gsub(' %(DC %d+%)', '')
			string_malady_linked_npc = string.lower(string_malady_linked_npc:gsub('%A', ''))
			local string_npc_name = DB.getValue(node_npc, 'name')
			string_npc_name = string.lower(string_npc_name:gsub('%A', ''))
			if string_malady_linked_npc == string_npc_name then
				local string_description = DB.getValue(node_npc, 'text', '')
				local string_malady_name = DB.getValue(node_malady, 'name', '')
				local string_malady_link = (
					'<linklist><link class="referencedisease" recordname="'
					.. DB.getPath(node_malady)
					.. '"><b>Malady: </b>'
					.. string_malady_name
					.. string_difficulty_class
					.. '</link></linklist>'
				)
				DB.setValue(node_npc, 'text', 'formattedtext', string_malady_link .. string_description)
			end
		end
	end
end

---	This function checks reference.diseases._ and disease._ for matching maladies.
--	It passes the appropriate nodes to the add_malady_link function.
--	It does nothing if the DiseaseTracker script isn't found.
local function search_for_maladies(node_npc)
	if DiseaseTracker then
		if DB.getValue(node_npc, 'name') then
			if DB.findNode('reference.diseases@*') then
				for _, node_malady in ipairs(DB.getChildList('reference.diseases@*')) do
					add_malady_link(node_malady, node_npc)
				end
			end
			if DB.findNode('disease') then
				for _, node_malady in ipairs(DB.getChildList('disease')) do
					add_malady_link(node_malady, node_npc)
				end
			end
		end
	end
end

--
--	ACTION AUTOMATION FUNCTIONS
--

local function add_ability_automation(node_npc, table_ability_information, number_rank, string_parenthetical)
	if
		not node_npc
		or table_ability_information['name'] == ''
		or not table_ability_information
		or table_ability_information == {}
		or (table_ability_information['daily_uses'] and table_ability_information['daily_uses'] < 0)
		or table_ability_information['level'] < 0
		or table_ability_information['level'] > 9
		or not table_ability_information['actions']
	then
		return
	end

	-- create spellset and intermediate subnodes
	local node_spellset = DB.createChild(node_npc, 'spellset')
	local node_spellclass = DB.createChild(node_spellset, table_ability_information['string_ability_type'] or 'Abilities')
	local node_spelllevel = DB.createChild(DB.createChild(node_spellclass, 'levels'), 'level' .. table_ability_information['level'])
	local node_ability = DB.createChild(DB.createChild(node_spelllevel, 'spells'))

	-- set up spellset and intermediate subnodes
	DB.setValue(node_spellclass, 'label', 'string', table_ability_information['string_ability_type'])
	DB.setValue(node_spellclass, 'castertype', 'string', 'spontaneous')
	DB.setValue(node_spellclass, 'availablelevel' .. table_ability_information['level'], 'number', table_ability_information['daily_uses'] or 1)
	DB.setValue(node_spellclass, 'cl', 'number', 0)
	DB.setValue(node_spelllevel, 'level', 'number', table_ability_information['level'])

	-- set name and description
	DB.setValue(node_ability, 'name', 'string', table_ability_information['name'])
	DB.setValue(node_ability, 'description', 'string', (table_ability_information['description'] or '') .. (string_parenthetical or ''))
	if table_ability_information['perday'] then
		DB.setValue(node_ability, 'prepared', 'number', table_ability_information['perday'])
	end
	DB.setValue(node_ability, 'sr', 'string', 'no')

	-- create actions
	local node_actions = DB.createChild(node_ability, 'actions')
	for string_name_action, table_action_information in pairs(table_ability_information['actions']) do
		local node_action = DB.createChild(node_actions, string_name_action)
		for string_node_name, table_node_info in pairs(table_action_information) do
			if string_node_name == 'damagelist' or string_node_name == 'heallist' then
				for string_damage_name, table_damage_information in pairs(table_node_info) do
					local node_damage = DB.createChild(DB.createChild(node_action, string_node_name), string_damage_name)
					for string_damagenode_name, table_damagenode_info in pairs(table_damage_information) do
						if table_damagenode_info['type'] and table_damagenode_info['value'] then
							if table_damagenode_info['tiermultiplier'] then
								if table_damagenode_info['type'] == 'string' then
									local string_result =
										string.format(table_damagenode_info['value'], (table_damagenode_info['tiermultiplier'] * (number_rank or 1)))
									DB.setValue(node_damage, string_damagenode_name, table_damagenode_info['type'], string_result)
								elseif table_damagenode_info['type'] == 'number' then
									local number_result = table_damagenode_info['value']
										* (table_damagenode_info['tiermultiplier'] * (number_rank or 1))
									DB.setValue(node_damage, string_damagenode_name, table_damagenode_info['type'], number_result)
								end
							else
								DB.setValue(node_damage, string_damagenode_name, table_damagenode_info['type'], table_damagenode_info['value'])
							end
						end
					end
				end
			else
				if table_node_info['type'] and table_node_info['value'] then
					if table_node_info['tiermultiplier'] then
						local result = string.format(table_node_info['value'], (table_node_info['tiermultiplier'] * (number_rank or 1)))
						DB.setValue(node_action, string_node_name, table_node_info['type'], result)
					else
						DB.setValue(node_action, string_node_name, table_node_info['type'], table_node_info['value'])
					end
				end
			end
		end
	end
end

---	This function breaks down a table of abilities and searches for them in an NPC sheet.
--	The search result is provided by the hasSpecialAbility function.
--	If a match is found, it triggers the function hasSpecialAbility.
local function search_for_abilities(node_npc)
	---	This function checks NPCs for feats, traits, and/or special abilities.
	local function hasSpecialAbility(nodeActor, sSearchString, sAbilType)
		if not nodeActor or not sSearchString then
			return false
		end

		local function matchInTable(table, search)
			for _, string in ipairs(table) do
				string = string:lower()

				local match = string:match(search:lower(), 1)
				if match then
					return match
				end
			end
		end

		local tScope = {}
		if sAbilType == 'Feats' then
			tScope = { DB.getValue(nodeActor, '.specialattacks', ''), DB.getValue(nodeActor, '.feats', '') }
		elseif sAbilType == 'Special Abilities' then
			tScope = { DB.getValue(nodeActor, '.specialattacks', ''), DB.getValue(nodeActor, '.specialqualities', '') }
		end

		return matchInTable(tScope, sSearchString) ~= nil,
			matchInTable(tScope, sSearchString .. ' (%d+)') or 1,
			matchInTable(tScope, sSearchString .. ' %((.-)%)')
	end

	for string_ability_name, table_ability_information in pairs(UNPCAbilities.array_abilities) do
		local is_match, number_rank, string_parenthetical =
			hasSpecialAbility(node_npc, string_ability_name, table_ability_information['string_ability_type'])

		if is_match then
			-- call ability parser function if supplied
			if string_parenthetical and table_ability_information['parser'] then
				table_ability_information['parser'](string_parenthetical, table_ability_information)
			end

			-- add ability
			add_ability_automation(node_npc, table_ability_information, number_rank, string_parenthetical)
		end
	end
end

-- Function Overrides
function onInit()
	---	This function is called when adding an NPC to the combat tracker.
	local addNPC_old -- placeholder for original addNPC function
	local function addNPC_new(tCustom, ...)
		addNPC_old(tCustom, ...) -- call original function

		local bAutomatedModule, tSourceModule = nil, Module.getModuleInfo(DB.getPath(tCustom['nodeRecord']):gsub('.+%@', ''))
		if tSourceModule then
			bAutomatedModule = tSourceModule['author'] == 'Tanor'
		end

		if not bAutomatedModule then
			find_spell_nodes(tCustom['nodeCT'])
			search_for_abilities(tCustom['nodeCT'])
			search_for_maladies(tCustom['nodeCT'])
		end
	end

	addNPC_old = CombatRecordManager.addNPC
	CombatRecordManager.addNPC = addNPC_new

	---	This function is called when clicking re-parse spell on the radial menu.
	--	It re-imports the spell details from the PFRPG - Spellbook module.
	--	If not Spellbook spell is found, it passes the call to the original addNPC function.
	local parseSpell_old -- placeholder for original parseSpell function
	local function parseSpell_new(nodeSpell, ...)
		if not nodeSpell then
			return nil
		end
		local node_reference_spell = replace_spell_actions(nodeSpell)
		-- if spellbook actions not found, run original parsing script
		if not node_reference_spell then
			parseSpell_old(nodeSpell, ...)
		end
	end

	parseSpell_old = SpellManager.parseSpell
	SpellManager.parseSpell = parseSpell_new
end
