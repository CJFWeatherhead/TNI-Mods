#ifndef TNI_API_HEADER_WORMBASE
#define TNI_API_HEADER_WORMBASE
// Generated API for game version 0.10.11
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct WormBase : public Node {
	using Node::Node;

	constexpr WormBase(Node base) : Node{base} {}
	constexpr WormBase(uint64_t addr) : Node{addr} {}
	constexpr WormBase(Object obj) : WormBase{obj.address()} {}
	WormBase(Variant variant) : WormBase{variant.as_object().address()} {}


	PROPERTY(release_name_template, String);
	PROPERTY(max_spread_per_tick, int64_t);
	PROPERTY(signature, String);
	PROPERTY(vulnerable_device_types, Variant);
	PROPERTY(incubation_cycles, int64_t);
	PROPERTY(incubation_ctr, int64_t);
	PROPERTY(traffic_class, String);
	PROPERTY(traffic_weight, int64_t);
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

	inline NetworkPacketRoot make_packet_root();
	inline Variant make_traversal_packet(NetworkPacketRoot proot);
	inline void tick();
	inline void client_sim();
	inline String colorize_description(String ds);
	inline void start();
	inline void stop();
	inline void uninstall();
	inline void install(Variant _install_opts);
	inline bool process_network_packet(PacketControlModule pktctl, Variant packet);
	inline bool is_pkt_for_self(Variant packet);
};

#include "LogicController.hpp"
#include "NetworkPacketRoot.hpp"
#include "PacketControlModule.hpp"

inline NetworkPacketRoot WormBase::make_packet_root() { return NetworkPacketRoot(operator()("make_packet_root").as_object().address()); }
inline Variant WormBase::make_traversal_packet(NetworkPacketRoot proot) { return operator()("make_traversal_packet", proot); }
inline void WormBase::tick() { voidcall("tick"); }
inline void WormBase::client_sim() { voidcall("client_sim"); }
inline String WormBase::colorize_description(String ds) { return operator()("colorize_description", ds); }
inline void WormBase::start() { voidcall("start"); }
inline void WormBase::stop() { voidcall("stop"); }
inline void WormBase::uninstall() { voidcall("uninstall"); }
inline void WormBase::install(Variant _install_opts) { voidcall("install", _install_opts); }
inline bool WormBase::process_network_packet(PacketControlModule pktctl, Variant packet) { return operator()("process_network_packet", pktctl, packet); }
inline bool WormBase::is_pkt_for_self(Variant packet) { return operator()("is_pkt_for_self", packet); }

#endif
