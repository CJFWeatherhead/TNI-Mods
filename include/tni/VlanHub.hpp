#ifndef TNI_API_HEADER_VLANHUB
#define TNI_API_HEADER_VLANHUB
// Generated API for game version 0.10.7
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct VlanHub : public Node {
	using Node::Node;

	constexpr VlanHub(Node base) : Node{base} {}
	constexpr VlanHub(uint64_t addr) : Node{addr} {}
	constexpr VlanHub(Object obj) : VlanHub{obj.address()} {}
	VlanHub(Variant variant) : VlanHub{variant.as_object().address()} {}


	PROPERTY(vlanctl, VLANControlModule);
	PROPERTY(networkctl, NetworkControlModule);
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
#include "NetworkControlModule.hpp"
#include "LogicController.hpp"
#include "PacketControlModule.hpp"

inline bool VlanHub::process_network_packet(PacketControlModule pktctl, Variant packet) { return operator()("process_network_packet", pktctl, packet); }
inline void VlanHub::tick() { voidcall("tick"); }
inline String VlanHub::colorize_description(String ds) { return operator()("colorize_description", ds); }
inline void VlanHub::start() { voidcall("start"); }
inline void VlanHub::stop() { voidcall("stop"); }
inline void VlanHub::uninstall() { voidcall("uninstall"); }
inline void VlanHub::install(Variant _install_opts) { voidcall("install", _install_opts); }
inline bool VlanHub::is_pkt_for_self(Variant packet) { return operator()("is_pkt_for_self", packet); }

#endif
