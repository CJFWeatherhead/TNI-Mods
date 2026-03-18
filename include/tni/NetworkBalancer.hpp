#ifndef TNI_API_HEADER_NETWORKBALANCER
#define TNI_API_HEADER_NETWORKBALANCER
// Generated API for game version 0.10.11
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct NetworkBalancer : public Node {
	using Node::Node;

	constexpr NetworkBalancer(Node base) : Node{base} {}
	constexpr NetworkBalancer(uint64_t addr) : Node{addr} {}
	constexpr NetworkBalancer(Object obj) : NetworkBalancer{obj.address()} {}
	NetworkBalancer(Variant variant) : NetworkBalancer{variant.as_object().address()} {}


	PROPERTY(networkctl, NetworkControlModule);
	PROPERTY(lbcounter, int64_t);
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

#include "NetworkControlModule.hpp"
#include "LogicController.hpp"
#include "PacketControlModule.hpp"

inline bool NetworkBalancer::process_network_packet(PacketControlModule pktctl, Variant packet) { return operator()("process_network_packet", pktctl, packet); }
inline void NetworkBalancer::tick() { voidcall("tick"); }
inline String NetworkBalancer::colorize_description(String ds) { return operator()("colorize_description", ds); }
inline void NetworkBalancer::start() { voidcall("start"); }
inline void NetworkBalancer::stop() { voidcall("stop"); }
inline void NetworkBalancer::uninstall() { voidcall("uninstall"); }
inline void NetworkBalancer::install(Variant _install_opts) { voidcall("install", _install_opts); }
inline bool NetworkBalancer::is_pkt_for_self(Variant packet) { return operator()("is_pkt_for_self", packet); }

#endif
