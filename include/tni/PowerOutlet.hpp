#ifndef TNI_API_HEADER_POWEROUTLET
#define TNI_API_HEADER_POWEROUTLET
// Generated API for game version 0.10.11
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct PowerOutlet : public Area2D {
	using Area2D::Area2D;

	constexpr PowerOutlet(Area2D base) : Area2D{base} {}
	constexpr PowerOutlet(uint64_t addr) : Area2D{addr} {}
	constexpr PowerOutlet(Object obj) : PowerOutlet{obj.address()} {}
	PowerOutlet(Variant variant) : PowerOutlet{variant.as_object().address()} {}


	PROPERTY(controller, GraphController);
	PROPERTY(current_floor, Location);
	PROPERTY(socket, Socket);
	PROPERTY(floor_num, int64_t);

	inline void remove();
	inline Variant debug_monitor_callback();
};

#include "GraphController.hpp"
#include "Location.hpp"
#include "Socket.hpp"

inline void PowerOutlet::remove() { voidcall("remove"); }
inline Variant PowerOutlet::debug_monitor_callback() { return operator()("debug_monitor_callback"); }

#endif
