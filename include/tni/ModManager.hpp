#ifndef TNI_API_HEADER_MODMANAGER
#define TNI_API_HEADER_MODMANAGER
// Generated API for game version 0.10.7
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct ModManager : public Control {
	using Control::Control;

	constexpr ModManager(Control base) : Control{base} {}
	constexpr ModManager(uint64_t addr) : Control{addr} {}
	constexpr ModManager(Object obj) : ModManager{obj.address()} {}
	ModManager(Variant variant) : ModManager{variant.as_object().address()} {}

	enum DependencyStatus : int64_t {  // NOTE: You should recompile your mod if this enum changes!
		LOADED = 0,
		UNLOADED = 1,
		WRONG_VERSION = 2,
		MISSING = 3,
	};

	PROPERTY(mod_list, VBoxContainer);
	PROPERTY(mod_preset_label, Label);
	PROPERTY(mod_info_container, VBoxContainer);
	PROPERTY(mod_info_name, Label);
	PROPERTY(mod_info_description, RichTextLabel);
	PROPERTY(mod_info_version, Label);
	PROPERTY(mod_info_dependencies_spacer, Separator);
	PROPERTY(mod_info_dependencies_label, Label);
	PROPERTY(mod_info_dependencies, HFlowContainer);
	PROPERTY(mod_info_optional_dependencies_spacer, Separator);
	PROPERTY(mod_info_optional_dependencies_label, Label);
	PROPERTY(mod_info_optional_dependencies, HFlowContainer);
	PROPERTY(mod_info_incompatibilities_spacer, Separator);
	PROPERTY(mod_info_incompatibilities_label, Label);
	PROPERTY(mod_info_incompatibilities, HFlowContainer);
	PROPERTY(mod_info_authors, Label);
	PROPERTY(mod_info_links, HBoxContainer);
	PROPERTY(preset_save_load_button, MenuButton);
	PROPERTY(mod_info_manifest, ModManifest);
	PROPERTY(preset, ModPreset);
	PROPERTY(preset_modified, bool);

	inline void fade_in();
	inline void fade_out();
	inline void update_preset_label();
	inline void update_mod_list();
	inline void set_mod_info(ModManifest manifest);
};

#include "ModManifest.hpp"
#include "ModPreset.hpp"

inline void ModManager::fade_in() { voidcall("fade_in"); }
inline void ModManager::fade_out() { voidcall("fade_out"); }
inline void ModManager::update_preset_label() { voidcall("update_preset_label"); }
inline void ModManager::update_mod_list() { voidcall("update_mod_list"); }
inline void ModManager::set_mod_info(ModManifest manifest) { voidcall("set_mod_info", manifest); }

#endif
