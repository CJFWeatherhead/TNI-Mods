#ifndef TNI_API_HEADER_HAROUTER
#define TNI_API_HEADER_HAROUTER
// Generated API for game version 0.10.11
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct HaRouter : public Node {
	using Node::Node;

	constexpr HaRouter(Node base) : Node{base} {}
	constexpr HaRouter(uint64_t addr) : Node{addr} {}
	constexpr HaRouter(Object obj) : HaRouter{obj.address()} {}
	HaRouter(Variant variant) : HaRouter{variant.as_object().address()} {}


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
	inline Variant get_longest_matched_port(Variant hc, Variant pktctl, Variant rtctl, Variant packet);
	inline void update_routes_from_rip_packet(LogicController src_node_controller, LogicController hopped_node_controller, String rcpt_port_id, String src_port_id);
	inline String colorize_description(String ds);
	inline void start();
	inline void stop();
	inline void uninstall();
	inline void install(Variant _install_opts);
	inline bool is_pkt_for_self(Variant packet);
};

#include "RouteControlModule.hpp"
#include "LogicController.hpp"
#include "PacketControlModule.hpp"

inline bool HaRouter::process_network_packet(PacketControlModule pktctl, Variant packet) { return operator()("process_network_packet", pktctl, packet); }
inline void HaRouter::tick() { voidcall("tick"); }
inline Variant HaRouter::get_longest_matched_port(Variant hc, Variant pktctl, Variant rtctl, Variant packet) { return operator()("get_longest_matched_port", hc, pktctl, rtctl, packet); }
inline void HaRouter::update_routes_from_rip_packet(LogicController src_node_controller, LogicController hopped_node_controller, String rcpt_port_id, String src_port_id) { voidcall("update_routes_from_rip_packet", src_node_controller, hopped_node_controller, rcpt_port_id, src_port_id); }
inline String HaRouter::colorize_description(String ds) { return operator()("colorize_description", ds); }
inline void HaRouter::start() { voidcall("start"); }
inline void HaRouter::stop() { voidcall("stop"); }
inline void HaRouter::uninstall() { voidcall("uninstall"); }
inline void HaRouter::install(Variant _install_opts) { voidcall("install", _install_opts); }
inline bool HaRouter::is_pkt_for_self(Variant packet) { return operator()("is_pkt_for_self", packet); }

#endif
