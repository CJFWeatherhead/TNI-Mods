#ifndef TNI_API_HEADER_POCOSIAPRIMITIVELINEDRAWER3D
#define TNI_API_HEADER_POCOSIAPRIMITIVELINEDRAWER3D
// Generated API for game version 0.10.11
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct PocosiaPrimitiveLineDrawer3D : public MeshInstance3D {
	using MeshInstance3D::MeshInstance3D;

	constexpr PocosiaPrimitiveLineDrawer3D(MeshInstance3D base) : MeshInstance3D{base} {}
	constexpr PocosiaPrimitiveLineDrawer3D(uint64_t addr) : MeshInstance3D{addr} {}
	constexpr PocosiaPrimitiveLineDrawer3D(Object obj) : PocosiaPrimitiveLineDrawer3D{obj.address()} {}
	PocosiaPrimitiveLineDrawer3D(Variant variant) : PocosiaPrimitiveLineDrawer3D{variant.as_object().address()} {}


	PROPERTY(redraw_frame_interval, int64_t);
	PROPERTY(ref_points, Variant);

	inline void redraw();
	inline void clear_all_lines();
	inline void clear_line(Variant ref);
	inline void draw_line(Variant ref, Variant global_a, Variant global_b, double thickness, Variant color);
	inline Variant get_references();
};


inline void PocosiaPrimitiveLineDrawer3D::redraw() { voidcall("redraw"); }
inline void PocosiaPrimitiveLineDrawer3D::clear_all_lines() { voidcall("clear_all_lines"); }
inline void PocosiaPrimitiveLineDrawer3D::clear_line(Variant ref) { voidcall("clear_line", ref); }
inline void PocosiaPrimitiveLineDrawer3D::draw_line(Variant ref, Variant global_a, Variant global_b, double thickness, Variant color) { voidcall("draw_line", ref, global_a, global_b, thickness, color); }
inline Variant PocosiaPrimitiveLineDrawer3D::get_references() { return operator()("get_references"); }

#endif
