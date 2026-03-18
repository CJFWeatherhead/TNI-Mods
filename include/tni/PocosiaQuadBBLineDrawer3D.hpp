#ifndef TNI_API_HEADER_POCOSIAQUADBBLINEDRAWER3D
#define TNI_API_HEADER_POCOSIAQUADBBLINEDRAWER3D
// Generated API for game version 0.10.11
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct PocosiaQuadBBLineDrawer3D : public MeshInstance3D {
	using MeshInstance3D::MeshInstance3D;

	constexpr PocosiaQuadBBLineDrawer3D(MeshInstance3D base) : MeshInstance3D{base} {}
	constexpr PocosiaQuadBBLineDrawer3D(uint64_t addr) : MeshInstance3D{addr} {}
	constexpr PocosiaQuadBBLineDrawer3D(Object obj) : PocosiaQuadBBLineDrawer3D{obj.address()} {}
	PocosiaQuadBBLineDrawer3D(Variant variant) : PocosiaQuadBBLineDrawer3D{variant.as_object().address()} {}


	PROPERTY(redraw_frame_interval, int64_t);
	PROPERTY(ref_points, Variant);

	inline void redraw();
	inline void clear_all_lines();
	inline void clear_line(Variant ref);
	inline void draw_line(Variant ref, Variant global_a, Variant global_b, double thickness, Variant color);
	inline Variant get_references();
};


inline void PocosiaQuadBBLineDrawer3D::redraw() { voidcall("redraw"); }
inline void PocosiaQuadBBLineDrawer3D::clear_all_lines() { voidcall("clear_all_lines"); }
inline void PocosiaQuadBBLineDrawer3D::clear_line(Variant ref) { voidcall("clear_line", ref); }
inline void PocosiaQuadBBLineDrawer3D::draw_line(Variant ref, Variant global_a, Variant global_b, double thickness, Variant color) { voidcall("draw_line", ref, global_a, global_b, thickness, color); }
inline Variant PocosiaQuadBBLineDrawer3D::get_references() { return operator()("get_references"); }

#endif
