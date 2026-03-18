#ifndef TNI_API_HEADER_NETWORKFIREWALL
#define TNI_API_HEADER_NETWORKFIREWALL
// Generated API for game version 0.10.11
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct NetworkFirewall : public Node {
	using Node::Node;

	constexpr NetworkFirewall(Node base) : Node{base} {}
	constexpr NetworkFirewall(uint64_t addr) : Node{addr} {}
	constexpr NetworkFirewall(Object obj) : NetworkFirewall{obj.address()} {}
	NetworkFirewall(Variant variant) : NetworkFirewall{variant.as_object().address()} {}


	PROPERTY(firewallctl, FirewallControlModule);
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

	inline bool process_network_packet(PacketControlModule _pktctl, Variant packet);
	inline void tick();
	inline String colorize_description(String ds);
	inline void start();
	inline void stop();
	inline void uninstall();
	inline void install(Variant _install_opts);
	inline bool is_pkt_for_self(Variant packet);
};

#include "FirewallControlModule.hpp"
#include "LogicController.hpp"
#include "PacketControlModule.hpp"

inline bool NetworkFirewall::process_network_packet(PacketControlModule _pktctl, Variant packet) { return operator()("process_network_packet", _pktctl, packet); }
inline void NetworkFirewall::tick() { voidcall("tick"); }
inline String NetworkFirewall::colorize_description(String ds) { return operator()("colorize_description", ds); }
inline void NetworkFirewall::start() { voidcall("start"); }
inline void NetworkFirewall::stop() { voidcall("stop"); }
inline void NetworkFirewall::uninstall() { voidcall("uninstall"); }
inline void NetworkFirewall::install(Variant _install_opts) { voidcall("install", _install_opts); }
inline bool NetworkFirewall::is_pkt_for_self(Variant packet) { return operator()("is_pkt_for_self", packet); }

#endif
