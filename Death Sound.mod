return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Death Sound` encountered an error loading the Darktide Mod Framework.")

		new_mod("Death Sound", {
			mod_script       = "Death Sound/scripts/mods/Death Sound/Death Sound",
			mod_data         = "Death Sound/scripts/mods/Death Sound/Death Sound_data",
			mod_localization = "Death Sound/scripts/mods/Death Sound/Death Sound_localization",
		})
	end,
	packages = {},
}
