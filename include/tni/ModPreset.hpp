#ifndef TNI_API_HEADER_MODPRESET
#define TNI_API_HEADER_MODPRESET
// Generated API for game version 0.10.7
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct ModPreset : public RefCounted {
	using RefCounted::RefCounted;

	constexpr ModPreset(RefCounted base) : RefCounted{base} {}
	constexpr ModPreset(uint64_t addr) : RefCounted{addr} {}
	constexpr ModPreset(Object obj) : ModPreset{obj.address()} {}
	ModPreset(Variant variant) : ModPreset{variant.as_object().address()} {}


	PROPERTY(name, String);
	PROPERTY(frozen, bool);
	PROPERTY(mods, Variant);

	inline ModPreset duplicate();
	inline Variant to_json();
	inline ModPreset from_json(Variant data);
	inline ModPreset with_minified_manifests();
	inline bool is_functionally_same(ModPreset other);
	inline void update_with_discovered();
	inline int64_t find(ModManifest mod);
	inline int64_t find_mod_id(String mod_id);
	inline bool add(ModManifest mod);
	inline bool remove(ModManifest mod);
	inline void lower_order_position(ModManifest mod);
	inline void reinsert_mod(ModManifest mod, int64_t position);
	inline void raise_order_position(ModManifest mod);
	inline int64_t get_actual_order_offset(ModManifest base, String addition_id);
	inline void auto_sort();
	inline PackedArray<std::string> get_mod_issues(ModManifest addition);
};

#include "ModPreset.hpp"
#include "ModManifest.hpp"

inline ModPreset ModPreset::duplicate() { return ModPreset(operator()("duplicate").as_object().address()); }
inline Variant ModPreset::to_json() { return operator()("to_json"); }
inline ModPreset ModPreset::from_json(Variant data) { return ModPreset(operator()("from_json", data).as_object().address()); }
inline ModPreset ModPreset::with_minified_manifests() { return ModPreset(operator()("with_minified_manifests").as_object().address()); }
inline bool ModPreset::is_functionally_same(ModPreset other) { return operator()("is_functionally_same", other); }
inline void ModPreset::update_with_discovered() { voidcall("update_with_discovered"); }
inline int64_t ModPreset::find(ModManifest mod) { return operator()("find", mod); }
inline int64_t ModPreset::find_mod_id(String mod_id) { return operator()("find_mod_id", mod_id); }
inline bool ModPreset::add(ModManifest mod) { return operator()("add", mod); }
inline bool ModPreset::remove(ModManifest mod) { return operator()("remove", mod); }
inline void ModPreset::lower_order_position(ModManifest mod) { voidcall("lower_order_position", mod); }
inline void ModPreset::reinsert_mod(ModManifest mod, int64_t position) { voidcall("reinsert_mod", mod, position); }
inline void ModPreset::raise_order_position(ModManifest mod) { voidcall("raise_order_position", mod); }
inline int64_t ModPreset::get_actual_order_offset(ModManifest base, String addition_id) { return operator()("get_actual_order_offset", base, addition_id); }
inline void ModPreset::auto_sort() { voidcall("auto_sort"); }
inline PackedArray<std::string> ModPreset::get_mod_issues(ModManifest addition) { return operator()("get_mod_issues", addition); }

#endif
