local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
chalk = mods['SGG_Modding-Chalk']
reload = mods['SGG_Modding-ReLoad']
local lib = mods['adamant-Modpack_Lib'].public

config = chalk.auto('config.lua')
public.config = config

local backup, restore = lib.createBackupSystem()

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
    dataMutation = false,
}

-- =============================================================================
-- MODULE LOGIC
-- =============================================================================

local function apply()
end

local function registerHooks()
    modutil.mod.Path.Wrap("EndEarlyAccessPresentation", function(baseFunc)
        if not config.Enabled then return baseFunc() end

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

public.definition.enable = apply
public.definition.disable = restore

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(function()
        import_as_fallback(rom.game)
        registerHooks()
        if config.Enabled then apply() end
        if public.definition.dataMutation and not mods['adamant-Core'] then
            SetupRunData()
        end
    end)
end)

lib.standaloneUI(public.definition, config, apply, restore)
