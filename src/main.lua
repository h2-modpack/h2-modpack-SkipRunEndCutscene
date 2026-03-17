-- =============================================================================
-- BOILERPLATE (do not modify)
-- =============================================================================

local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']

config = chalk.auto('config.lua')
public.config = config

local NIL = {}
local backups = {}

local function backup(tbl, key)
    if not backups[tbl] then backups[tbl] = {} end
    if backups[tbl][key] == nil then
        local v = tbl[key]
        backups[tbl][key] = v == nil and NIL or (type(v) == "table" and DeepCopyTable(v) or v)
    end
end

local function restore()
    for tbl, keys in pairs(backups) do
        for key, v in pairs(keys) do
            tbl[key] = v == NIL and nil or (type(v) == "table" and DeepCopyTable(v) or v)
        end
    end
end

local function isEnabled()
    return config.Enabled
end

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "RunEndCutscene",
    name     = "Skip End Run Cutscene",
    category = "QoLSettings",
    group    = "QoL",
    tooltip  = "Skip the end-of-run cutscene. The victory screen will still appear, but you will be immediately returned to the main menu.",
    default  = true,
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
end

local function disable()
    restore()
end

local function registerHooks()
    modutil.mod.Path.Wrap("EndEarlyAccessPresentation", function(baseFunc)
        if not isEnabled() then return baseFunc() end

        AddInputBlock({ Name = "EndEarlyAccessPresentation" })
        SetPlayerInvulnerable("EndEarlyAccessPresentation")

        CurrentRun.Hero.Mute = true
        CurrentRun.ActiveBiomeTimer = false
        ToggleCombatControl(CombatControlsDefaults, false, "EarlyAccessPresentation")

        wait(0.1)
        StopAmbientSound({ All = true })
        SetAudioEffectState({ Name = "Reverb", Value = 1.5 })
        EndAmbience(0.5)
        EndAllBiomeStates()
        FadeOut({ Duration = 0.375, Color = Color.Black })

        EndBiomeRecords()
        RecordRunCleared()

        SetPlayerVulnerable("EndEarlyAccessPresentation")
        RemoveInputBlock({ Name = "EndEarlyAccessPresentation" })
        ToggleCombatControl(CombatControlsDefaults, true, "EarlyAccessPresentation")

        CurrentRun.Hero.Mute = false
        thread(Kill, CurrentRun.Hero)
        wait(0.15)

        FadeIn({ Duration = 0.5 })
    end)
end

-- =============================================================================
-- PUBLIC API (do not modify)
-- =============================================================================

public.definition.enable = function()
    apply()
end

public.definition.disable = function()
    disable()
end

-- =============================================================================
-- LIFECYCLE (do not modify)
-- =============================================================================

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if config.Enabled then apply() end
    end)
end)

-- =============================================================================
-- STANDALONE UI (do not modify)
-- =============================================================================
-- When adamant-core is NOT installed, renders a minimal ImGui toggle.
-- When adamant-core IS installed, the core handles UI — this is skipped.

local imgui = rom.ImGui

local showWindow = false

rom.gui.add_imgui(function()
    if mods['adamant-Core'] then return end
    if not showWindow then return end

    if imgui.Begin(public.definition.name, true) then
        local val, chg = imgui.Checkbox("Enabled", config.Enabled)
        if chg then
            config.Enabled = val
            if val then apply() else disable() end
        end
        if imgui.IsItemHovered() and public.definition.tooltip ~= "" then
            imgui.SetTooltip(public.definition.tooltip)
        end
        imgui.End()
    else
        showWindow = false
    end
end)

rom.gui.add_to_menu_bar(function()
    if mods['adamant-Core'] then return end
    if imgui.BeginMenu("adamant") then
        if imgui.MenuItem(public.definition.name) then
            showWindow = not showWindow
        end
        imgui.EndMenu()
    end
end)
