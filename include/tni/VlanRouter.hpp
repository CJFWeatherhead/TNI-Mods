#ifndef TNI_API_HEADER_VLANROUTER
#define TNI_API_HEADER_VLANROUTER
// Generated API for game version 0.10.7
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct VlanRouter : public Node {
	using Node::Node;

	constexpr VlanRouter(Node base) : Node{base} {}
	constexpr VlanRouter(uint64_t addr) : Node{addr} {}
	constexpr VlanRouter(Object obj) : VlanRouter{obj.address()} {}
	VlanRouter(Variant variant) : VlanRouter{variant.as_object().address()} {}


	PROPERTY(vlanctl, VLANControlModule);
	PROPERTY(routectl, RouteControlModule);
	PROPERTY(cpu_load, int64_t);
	PROPERTY(code_size, int64_t);
	PROPERTY(stack_size, int64_t);
	PROPERTY(release_name, String);
	PROPERTY(description, String);
	PROPERTY(modifiers, Variant);
	PROPERTY(application_unlocks, Variant);
	PROPERTY(required_hardware_device, Variant);
	PROPERTY(data_size, int64_t);
	PROPERTY(install_size, int64_t);
	PROPERTY(rendered_description, String);
	PROPERTY(pkt_processing_priority, int64_t);
	PROPERTY(is_running, bool);
	PROPERTY(host_controller, LogicController);

	inline bool process_network_packet(PacketControlModule pktctl, Variant packet);
	inline void tick();
	inline String colorize_description(String ds);
	inline void start();
	inline void stop();
	inline void uninstall();
	inline void install(Variant _install_opts);
	inline bool is_pkt_for_self(Variant packet);
};

#include "VLANControlModule.hpp"
#include "RouteControlModule.hpp"
#include "LogicController.hpp"
#include "PacketControlModule.hpp"

inline bool VlanRouter::process_network_packet(PacketControlModule pktctl, Variant packet) { return operator()("process_network_packet", pktctl, packet); }
inline void VlanRouter::tick() { voidcall("tick"); }
inline String VlanRouter::colorize_description(String ds) { return operator()("colorize_description", ds); }
inline void VlanRouter::start() { voidcall("start"); }
inline void VlanRouter::stop() { voidcall("stop"); }
inline void VlanRouter::uninstall() { voidcall("uninstall"); }
inline void VlanRouter::install(Variant _install_opts) { voidcall("install", _install_opts); }
inline bool VlanRouter::is_pkt_for_self(Variant packet) { return operator()("is_pkt_for_self", packet); }

#endif
