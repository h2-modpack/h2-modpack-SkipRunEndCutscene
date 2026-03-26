local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-Modpack_Lib']

config = chalk.auto('config.lua')
public.config = config

local _, revert = lib.createBackupSystem()

-- =============================================================================
-- MODULE DEFINITION
-- =============================================================================

public.definition = {
    id       = "RunEndCutscene",
    name     = "Skip End Run Cutscene",
    category = "QoL",
    group    = "QoL",
    tooltip  = "Skip the end-of-run cutscene. The victory screen will still appear, but you will be immediately returned to the main menu.",
    default  = true,
    dataMutation = false,
    modpack = "h2-modpack",
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
end

local function registerHooks()
    modutil.mod.Path.Wrap("EndEarlyAccessPresentation", function(baseFunc)
        if not lib.isEnabled(config, public.definition.modpack) then return baseFunc() end

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
-- Wiring
-- =============================================================================

public.definition.apply = apply
public.definition.revert = revert

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if lib.isEnabled(config, public.definition.modpack) then apply() end
        if public.definition.dataMutation and not lib.isCoordinated(public.definition.modpack) then
            SetupRunData()
        end
    end)
end)

local uiCallback = lib.standaloneUI(public.definition, config, apply, revert)
rom.gui.add_to_menu_bar(uiCallback)
