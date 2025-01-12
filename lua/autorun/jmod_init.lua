AddCSLuaFile()
JMod = JMod or {}
-- EZ radio stations
JMod.EZ_RADIO_STATIONS = {}
JMod.EZ_STATION_STATE_READY = 2
JMod.EZ_STATION_STATE_DELIVERING = 3
JMod.EZ_STATION_STATE_BUSY = 4

-- resource definitions --
JMod.EZ_RESOURCE_TYPES = {
	WATER = "water",
	WOOD = "wood",
	ORGANICS = "organics",
	OIL = "oil",
	GAS = "gas",
	POWER = "power",
	DIAMOND = "diamond",
	COAL = "coal",
	--
	IRONORE = "iron ore",
	LEADORE = "lead ore",
	ALUMINUMORE = "aluminum ore",
	COPPERORE = "copper ore",
	TUNGSTENORE = "tungsten ore",
	TITANIUMORE = "titanium ore",
	SILVERORE = "silver ore",
	GOLDORE = "gold ore",
	URANIUMORE = "uranium ore",
	PLATINUMORE = "platinum ore",
	--
	STEEL = "steel",
	LEAD = "lead",
	ALUMINUM = "aluminum",
	COPPER = "copper",
	TUNGSTEN = "tungsten",
	TITANIUM = "titanium",
	SILVER = "silver",
	GOLD = "gold",
	URANIUM = "uranium",
	PLATINUM = "platinum",
	--
	FUEL = "fuel",
	PLASTIC = "plastic",
	RUBBER = "rubber",
	GLASS = "glass",
	CLOTH = "cloth",
	CERAMIC = "ceramic",
	PAPER = "paper",
	SAND = "sand",
	CONCRETE = "concrete",
	--
	AMMO = "ammo",
	MUNITIONS = "munitions",
	PROPELLANT = "propellant",
	EXPLOSIVES = "explosives",
	MEDICALSUPPLIES = "medical supplies",
	CHEMICALS = "chemicals",
	NUTRIENTS = "nutrients",
	COOLANT = "coolant",
	--
	BASICPARTS = "basic parts",
	PRECISIONPARTS = "precision parts",
	ADVANCEDTEXTILES = "advanced textiles",
	ADVANCEDPARTS = "advanced parts",
	FISSILEMATERIAL = "fissile material",
	--
	ANTIMATTER = "antimatter"
}

JMod.PrimitiveResourceTypes = {
	["wood"] = { JMod.EZ_RESOURCE_TYPES.WOOD },
	["metal"] = {JMod.EZ_RESOURCE_TYPES.COPPER, JMod.EZ_RESOURCE_TYPES.STEEL },
	["rock"] = { JMod.EZ_RESOURCE_TYPES.CONCRETE, JMod.EZ_RESOURCE_TYPES.CERAMIC }
}

JMod.ResourceToIndex = {}
JMod.IndexToResource = {}

for keyNumber, keyName in pairs(table.GetKeys(JMod.EZ_RESOURCE_TYPES)) do
	local value = JMod.EZ_RESOURCE_TYPES[keyName]
	JMod.ResourceToIndex[value] = keyNumber
	JMod.IndexToResource[keyNumber] = value
end

JMod.EZ_RESOURCE_TYPE_ICONS = {}
JMod.EZ_RESOURCE_TYPE_ICONS_SMOL = {}

for k, v in pairs(JMod.EZ_RESOURCE_TYPES) do
	JMod.EZ_RESOURCE_TYPE_ICONS[v] = Material("ez_resource_icons/" .. v .. ".png", "smooth 1")
	JMod.EZ_RESOURCE_TYPE_ICONS_SMOL[v] = Material("ez_resource_icons/" .. v .. " smol.png", "smooth 1")
end

JMod.EZ_RESOURCE_ENTITIES = {
	[JMod.EZ_RESOURCE_TYPES.WATER] = "ent_jack_gmod_ezwater",
	[JMod.EZ_RESOURCE_TYPES.WOOD] = "ent_jack_gmod_ezwood",
	[JMod.EZ_RESOURCE_TYPES.ORGANICS] = "ent_jack_gmod_ezorganics",
	[JMod.EZ_RESOURCE_TYPES.OIL] = "ent_jack_gmod_ezoil",
	[JMod.EZ_RESOURCE_TYPES.GAS] = "ent_jack_gmod_ezgas",
	[JMod.EZ_RESOURCE_TYPES.POWER] = "ent_jack_gmod_ezbattery",
	[JMod.EZ_RESOURCE_TYPES.DIAMOND] = "ent_jack_gmod_ezdiamond",
	[JMod.EZ_RESOURCE_TYPES.COAL] = "ent_jack_gmod_ezcoal",
	[JMod.EZ_RESOURCE_TYPES.IRONORE] = "ent_jack_gmod_ezironore",
	[JMod.EZ_RESOURCE_TYPES.LEADORE] = "ent_jack_gmod_ezleadore",
	[JMod.EZ_RESOURCE_TYPES.ALUMINUMORE] = "ent_jack_gmod_ezaluminumore",
	[JMod.EZ_RESOURCE_TYPES.COPPERORE] = "ent_jack_gmod_ezcopperore",
	[JMod.EZ_RESOURCE_TYPES.TUNGSTENORE] = "ent_jack_gmod_eztungstenore",
	[JMod.EZ_RESOURCE_TYPES.TITANIUMORE] = "ent_jack_gmod_eztitaniumore",
	[JMod.EZ_RESOURCE_TYPES.SILVERORE] = "ent_jack_gmod_ezsilverore",
	[JMod.EZ_RESOURCE_TYPES.GOLDORE] = "ent_jack_gmod_ezgoldore",
	[JMod.EZ_RESOURCE_TYPES.URANIUMORE] = "ent_jack_gmod_ezuraniumore",
	[JMod.EZ_RESOURCE_TYPES.PLATINUMORE] = "ent_jack_gmod_ezplatinumore",
	[JMod.EZ_RESOURCE_TYPES.STEEL] = "ent_jack_gmod_ezsteel",
	[JMod.EZ_RESOURCE_TYPES.LEAD] = "ent_jack_gmod_ezlead",
	[JMod.EZ_RESOURCE_TYPES.ALUMINUM] = "ent_jack_gmod_ezaluminum",
	[JMod.EZ_RESOURCE_TYPES.COPPER] = "ent_jack_gmod_ezcopper",
	[JMod.EZ_RESOURCE_TYPES.TUNGSTEN] = "ent_jack_gmod_eztungsten",
	[JMod.EZ_RESOURCE_TYPES.TITANIUM] = "ent_jack_gmod_eztitanium",
	[JMod.EZ_RESOURCE_TYPES.SILVER] = "ent_jack_gmod_ezsilver",
	[JMod.EZ_RESOURCE_TYPES.GOLD] = "ent_jack_gmod_ezgold",
	[JMod.EZ_RESOURCE_TYPES.URANIUM] = "ent_jack_gmod_ezuranium",
	[JMod.EZ_RESOURCE_TYPES.PLATINUM] = "ent_jack_gmod_ezplatinum",
	[JMod.EZ_RESOURCE_TYPES.FUEL] = "ent_jack_gmod_ezfuel",
	[JMod.EZ_RESOURCE_TYPES.PLASTIC] = "ent_jack_gmod_ezplastic",
	[JMod.EZ_RESOURCE_TYPES.RUBBER] = "ent_jack_gmod_ezrubber",
	[JMod.EZ_RESOURCE_TYPES.GLASS] = "ent_jack_gmod_ezglass",
	[JMod.EZ_RESOURCE_TYPES.CLOTH] = "ent_jack_gmod_ezcloth",
	[JMod.EZ_RESOURCE_TYPES.CERAMIC] = "ent_jack_gmod_ezceramic",
	[JMod.EZ_RESOURCE_TYPES.PAPER] = "ent_jack_gmod_ezpaper",
	[JMod.EZ_RESOURCE_TYPES.AMMO] = "ent_jack_gmod_ezammo",
	[JMod.EZ_RESOURCE_TYPES.MUNITIONS] = "ent_jack_gmod_ezmunitions",
	[JMod.EZ_RESOURCE_TYPES.PROPELLANT] = "ent_jack_gmod_ezpropellant",
	[JMod.EZ_RESOURCE_TYPES.EXPLOSIVES] = "ent_jack_gmod_ezexplosives",
	[JMod.EZ_RESOURCE_TYPES.MEDICALSUPPLIES] = "ent_jack_gmod_ezmedsupplies",
	[JMod.EZ_RESOURCE_TYPES.CHEMICALS] = "ent_jack_gmod_ezchemicals",
	[JMod.EZ_RESOURCE_TYPES.NUTRIENTS] = "ent_jack_gmod_eznutrients",
	[JMod.EZ_RESOURCE_TYPES.COOLANT] = "ent_jack_gmod_ezcoolant",
	[JMod.EZ_RESOURCE_TYPES.BASICPARTS] = "ent_jack_gmod_ezbasicparts",
	[JMod.EZ_RESOURCE_TYPES.PRECISIONPARTS] = "ent_jack_gmod_ezprecparts",
	[JMod.EZ_RESOURCE_TYPES.ADVANCEDTEXTILES] = "ent_jack_gmod_ezadvtextiles",
	[JMod.EZ_RESOURCE_TYPES.ADVANCEDPARTS] = "ent_jack_gmod_ezadvparts",
	[JMod.EZ_RESOURCE_TYPES.FISSILEMATERIAL] = "ent_jack_gmod_ezfissilematerial",
	[JMod.EZ_RESOURCE_TYPES.ANTIMATTER] = "ent_jack_gmod_ezantimatter",
	[JMod.EZ_RESOURCE_TYPES.SAND] = "ent_jack_gmod_ezsand",
	[JMod.EZ_RESOURCE_TYPES.CONCRETE] = "ent_jack_gmod_ezconcrete"
}

JMod.EZ_RESOURCE_TYPE_METHODS = {
	[JMod.EZ_RESOURCE_TYPES.BASICPARTS] = "BasicParts",
	[JMod.EZ_RESOURCE_TYPES.POWER] = "Electricity",
	[JMod.EZ_RESOURCE_TYPES.GAS] = "Gas",
	[JMod.EZ_RESOURCE_TYPES.COOLANT] = "Coolant",
	[JMod.EZ_RESOURCE_TYPES.WATER] = "Water",
	[JMod.EZ_RESOURCE_TYPES.CHEMICALS] = "Chemicals",
	[JMod.EZ_RESOURCE_TYPES.OIL] = "Oil",
	[JMod.EZ_RESOURCE_TYPES.FUEL] = "Fuel",
	[JMod.EZ_RESOURCE_TYPES.AMMO] = "Ammo",
	[JMod.EZ_RESOURCE_TYPES.MUNITIONS] = "Munitions",
	[JMod.EZ_RESOURCE_TYPES.MEDICALSUPPLIES] = "Supplies",
	[JMod.EZ_RESOURCE_TYPES.COAL] = "Coal",
	[JMod.EZ_RESOURCE_TYPES.SAND] = "Sand",
	[JMod.EZ_RESOURCE_TYPES.CONCRETE] = "Concrete"
}

JMod.EZ_WEIGHTLESS_RESOURCE_TYPES = {
	[JMod.EZ_RESOURCE_TYPES.POWER] = true,
	[JMod.EZ_RESOURCE_TYPES.ANTIMATTER] = true
}

-- EZ item quality grade (upgrade level) definitions
JMod.EZ_GRADE_BASIC = 1
JMod.EZ_GRADE_COPPER = 2
JMod.EZ_GRADE_SILVER = 3
JMod.EZ_GRADE_GOLD = 4
JMod.EZ_GRADE_PLATINUM = 5

JMod.EZ_GRADE_BUFFS = {1, 1.25, 1.5, 1.75, 2}

JMod.EZ_GRADE_NAMES = {"basic", "copper", "silver", "gold", "platinum"}

JMod.EZ_GRADE_MATS = {Material("models/mats_jack_grades/1"), Material("models/mats_jack_grades/2"), Material("models/mats_jack_grades/3"), Material("models/mats_jack_grades/4"), Material("models/mats_jack_grades/5")}

JMod.EZ_GRADE_UPGRADE_COSTS = {.5, 1, 1.5, 2}

JMod.EZ_UPGRADE_RESOURCE_BLACKLIST = {}
-- State enums
JMod.EZ_STATE_BROKEN = -1
JMod.EZ_STATE_OFF = 0
JMod.EZ_STATE_ON = 1
JMod.EZ_STATE_PRIMED = 2
JMod.EZ_STATE_ARMING = 3
JMod.EZ_STATE_ARMED = 4
JMod.EZ_STATE_WARNING = 5

JMod.EZ_HAZARD_PARTICLES = {
	["ent_jack_gmod_ezcsparticle"] = {JMod.EZ_RESOURCE_TYPES.CHEMICALS, .2},
	["ent_jack_gmod_ezgasparticle"] = {JMod.EZ_RESOURCE_TYPES.CHEMICALS, .5},
	["ent_jack_gmod_ezvirusparticle"] = {JMod.EZ_RESOURCE_TYPES.CHEMICALS, .1},
	["ent_jack_gmod_ezfalloutparticle"] = {JMod.EZ_RESOURCE_TYPES.FISSILEMATERIAL, .2}
}

JMod.RadiationShieldingValues = {
	[MAT_METAL] = .2,
	[MAT_CONCRETE] = .15,
	[MAT_DIRT] = .1,
	[MAT_GRASS] = .1,
	[MAT_SAND] = .07,
	[MAT_SNOW] = .07,
	[MAT_TILE] = .06,
	[MAT_WOOD] = .05,
	[MAT_GLASS] = .05,
	[MAT_PLASTIC] = .04
}

JMod.MapSolarPowerModifiers = {
	{
		{"clouds_", "_clouds", "cloudy_", "_cloudy"},
		.5
	},
	{
		{"stormy_", "storm_", "_storm", "_shady", "shady_", "_marsh", "marsh_"},
		.2
	},
	{
		{"_night", "night_"},
		0
	}
}

-- this table is just a bunch of assumptions
-- so that we have something to fall back on for camoflauge
-- obviously hand-picked colors will be better, but hey
JMod.HitMatColors = {
	[MAT_ANTLION] = {Color(194, 193, 109)},
	[MAT_BLOODYFLESH] = {Color(116, 57, 50)},
	[MAT_CONCRETE] = {Color(202, 202, 202)},
	[MAT_DIRT] = {Color(212, 199, 185)},
	[MAT_EGGSHELL] = {Color(255, 255, 230)},
	[MAT_FLESH] = {Color(136, 64, 64)},
	[MAT_GRATE] = {Color(148, 132, 122)},
	[MAT_ALIENFLESH] = {Color(220, 31, 31)},
	[MAT_SNOW] = {Color(242, 242, 242), "models/debug/debugwhite"},
	[MAT_PLASTIC] = {Color(242, 242, 242)},
	[MAT_METAL] = {Color(144, 124, 110)},
	[MAT_SAND] = {Color(244, 222, 197)},
	[MAT_FOLIAGE] = {Color(67, 72, 40)},
	[MAT_COMPUTER] = {Color(242, 242, 242)},
	[MAT_SLOSH] = {Color(108, 85, 58)},
	[MAT_TILE] = {Color(255, 255, 230)},
	[MAT_GRASS] = {Color(134, 158, 93)},
	[MAT_VENT] = {Color(144, 124, 110)},
	[MAT_WOOD] = {Color(190, 171, 141)},
	[MAT_DEFAULT] = {Color(128, 128, 128)},
	[MAT_GLASS] = {Color(200, 200, 255)},
	[MAT_WARPSHIELD] = {Color(255, 255, 255)}
}

JMod.DefualtArmorTable={
	[DMG_BUCKSHOT]=.1,
	[DMG_CRUSH]=.5,
	[DMG_VEHICLE]=.5,
	[DMG_BULLET]=.2,
	[DMG_SLASH]=.2,
	[DMG_BLAST]=1,
	[DMG_BLAST_SURFACE]=1,
	[DMG_CLUB]=.5,
	[DMG_SHOCK]=1,
	[DMG_BURN]=.3,
	[DMG_SLOWBURN]=.3,
	[DMG_ACID]=.4,
	[DMG_PLASMA]=.4,
	[DMG_AIRBOAT]=.75,
	[DMG_SONIC]=.1,
	-- Machines should never be damaged by these
	[DMG_DROWN]=0,
	[DMG_PARALYZE]=0,
	[DMG_NERVEGAS]=0,
	[DMG_POISON]=0,
	[DMG_RADIATION]=0,
	-- These damages should always be applied
	[DMG_SNIPER]=1,
	[DMG_GENERIC]=1,
	[DMG_FALL]=1,
	[DMG_ENERGYBEAM]=1,
	[DMG_PHYSGUN]=1,
	[DMG_DIRECT]=1,
	[DMG_DISSOLVE]=1,
	[DMG_MISSILEDEFENSE]=1
}

JMod.TreeArmorTable={
	[DMG_SLASH]=1.1,
	[DMG_BLAST]=1.1,
	[DMG_CLUB]=1.1,
	[DMG_BUCKSHOT]=.1,
	[DMG_SNIPER]=.2,
	[DMG_CRUSH]=.9,
	[DMG_BULLET]=.1,
	[DMG_SHOCK]=.9,
	[DMG_BURN]=.3,
	[DMG_SLOWBURN]=.3,
	[DMG_AIRBOAT]=.5,
	[DMG_PLASMA]=.3,
	[DMG_RADIATION]=.2,
	-- These values are more black and white
	[DMG_POISON]=0,
	[DMG_DROWN]=0,
	[DMG_PARALYZE]=0,
	[DMG_NERVEGAS]=0,
	[DMG_FALL]=0,
	[DMG_SONIC]=0,
	[DMG_ENERGYBEAM]=1,
	[DMG_PHYSGUN]=1,
	[DMG_ACID]=1,
	[DMG_VEHICLE]=1,
	[DMG_DISSOLVE]=1,
	[DMG_BLAST_SURFACE]=1,
	[DMG_DIRECT]=1,
	[DMG_GENERIC]=1,
	[DMG_MISSILEDEFENSE]=1
}

JMod.EZ_OwnerID = {}

-- we have to load locales before any other files
-- because files that add concommands have help text
-- and we want the help text to be localized
include("jmod/sh_locales.lua")
AddCSLuaFile("jmod/sh_locales.lua")

for i, f in pairs(file.Find("jmod/*.lua", "LUA")) do
	if string.Left(f, 3) == "sv_" then
		if SERVER then
			include("jmod/" .. f)
		end
	elseif string.Left(f, 3) == "cl_" then
		if CLIENT then
			include("jmod/" .. f)
		else
			AddCSLuaFile("jmod/" .. f)
		end
	elseif string.Left(f, 3) == "sh_" then
		AddCSLuaFile("jmod/" .. f)
		include("jmod/" .. f)
	else
		print("JMod detected unaccounted-for lua file '" .. f .. "'-check prefixes!")
	end
end

local PrimitiveBenchReqs = {[JMod.EZ_RESOURCE_TYPES.WOOD] = 25, [JMod.EZ_RESOURCE_TYPES.CERAMIC] = 15, [JMod.EZ_RESOURCE_TYPES.STEEL] = 8}

local Handcraft = function(ply, cmd, args)
	local Pos = ply:GetPos()
	local ScrapResources, LocalScrap = JMod.FindSuitableScrap(Pos, 200, ply)
	local ResourcesFromResourceEntities = JMod.CountResourcesInRange(nil, nil, ply)
	local AvailableResources = {}
	for k, v in pairs(ScrapResources) do
		AvailableResources[k] = (AvailableResources[k] or 0) + v
	end
	for k, v in pairs(ResourcesFromResourceEntities) do
		AvailableResources[k] = (AvailableResources[k] or 0) + v
	end
	local EnoughStuff, StuffLeft = JMod.HaveResourcesToPerformTask(nil, nil, PrimitiveBenchReqs, nil, AvailableResources)
	if EnoughStuff then
		local WherePutBench = util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 100, ply)
		JMod.BuildEffect(WherePutBench.HitPos + Vector(0, 0, 30))
		timer.Simple(0.5, function()
			local Bench = ents.Create("ent_jack_gmod_ezprimitivebench")
			Bench:SetPos(WherePutBench.HitPos + Vector(0, 0, 30))
			Bench:SetAngles(-ply:GetAngles())
			Bench:Spawn()
			JMod.SetEZowner(Bench, ply)
			Bench:Activate()
		end)
		
		local AllDone, Moar = JMod.ConsumeResourcesInRange(PrimitiveBenchReqs, Pos, 200, ply, false, LocalScrap)
		if not AllDone then
			JMod.ConsumeResourcesInRange(Moar, Pos, 200, ply, false)
		end
	else
		local Mssg = ""
		for k, v in pairs(StuffLeft) do
			Mssg = Mssg .. tostring(v) .. " more " .. tostring(k) .. ", "
		end
		ply:PrintMessage(HUD_PRINTCENTER, "You need: " .. string.sub(Mssg, 1, -3))
	end
end

-- This needs to be here I guess, probably due to load order
JMod.EZ_CONCOMMANDS = {
	{name = "inv", func = JMod.EZ_Open_Inventory, helpTxt = "Opens your EZ inventory to manage your armour.", noShow = true},
	{name = "bombdrop", func = JMod.EZ_BombDrop, helpTxt = "Drops any bombs you have armed and welded."},
	{name = "launch", func = JMod.EZ_WeaponLaunch, helpTxt = "Fires any active missiles you own."},
	{name = "trigger", func = JMod.EZ_Remote_Trigger,  helpTxt = "Triggers any EZ bombs/mini-nades you have armed."},
	{name = "scrounge", func = JMod.EZ_ScroungeArea, helpTxt = "Scrounges area for useful props to salvage."},
	{name = "grab", func = JMod.EZ_GrabItem, helpTxt = "Grabs the item and tries to put it in your inventory"},
	{name = "handcraft", func = Handcraft, helpTxt = "Construct crafting table from scrap."},
	{name = "config", func = JMod.EZ_Open_ConfigUI, helpTxt = "Opens the EZ config editor.", adminOnly = true}
}

if SERVER then
	for _, v in ipairs(JMod.EZ_CONCOMMANDS) do
		concommand.Add("jmod_ez_"..v.name, function(ply, cmd, args)
			if not (IsValid(ply) and ply:Alive()) then return end
			if v.adminOnly and not(JMod.IsAdmin(ply)) then ply:PrintMessage(HUD_PRINTCENTER, "This command is admin only") return end
			v.func(ply, cmd, args)
		end, nil, v.helpTxt)
	end
end

JMod.EZ_RESOURCE_INV_WEIGHT = .5