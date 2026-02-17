#ifndef TNI_API_HEADER_MODLOADER
#define TNI_API_HEADER_MODLOADER
// Generated API for game version 0.10.7
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct ModLoader : public Node {
	using Node::Node;

	constexpr ModLoader(Node base) : Node{base} {}
	constexpr ModLoader(uint64_t addr) : Node{addr} {}
	constexpr ModLoader(Object obj) : ModLoader{obj.address()} {}
	ModLoader(Variant variant) : ModLoader{variant.as_object().address()} {}

	inline static const String PRESET_FILE = "user://mod_preset.json";  // NOTE: You should recompile your mod if this value changes!
	inline static const String MOD_DIR = "user://mods/";  // NOTE: You should recompile your mod if this value changes!

	PROPERTY(lua_enabled, bool);
	PROPERTY(lua_elf_path, String);
	PROPERTY(discovered_mods, Variant);
	PROPERTY(preset, ModPreset);
	PROPERTY(loaded_mods, Variant);
	PROPERTY(mod_restrictions, Object);
	PROPERTY(has_reloaded, bool);

	inline void rediscover_mods();
	inline Mod try_load_mod(ModManifest manifest);
	inline void reload_mods();
	inline void game_host_eod();
	inline void game_state_ready();
	inline void device_spawned(DeviceUnit device);
	inline void user_spawned(LogicControllerUser user);
	inline void location_spawned(Location location);
};

#include "ModPreset.hpp"
#include "ModManifest.hpp"
#include "Mod.hpp"
#include "DeviceUnit.hpp"
#include "LogicControllerUser.hpp"
#include "Location.hpp"

inline void ModLoader::rediscover_mods() { voidcall("rediscover_mods"); }
inline Mod ModLoader::try_load_mod(ModManifest manifest) { return Mod(operator()("try_load_mod", manifest).as_object().address()); }
inline void ModLoader::reload_mods() { voidcall("reload_mods"); }
inline void ModLoader::game_host_eod() { voidcall("game_host_eod"); }
inline void ModLoader::game_state_ready() { voidcall("game_state_ready"); }
inline void ModLoader::device_spawned(DeviceUnit device) { voidcall("device_spawned", device); }
inline void ModLoader::user_spawned(LogicControllerUser user) { voidcall("user_spawned", user); }
inline void ModLoader::location_spawned(Location location) { voidcall("location_spawned", location); }

#endif
