#ifndef TNI_API_HEADER_TRAVERSALBASE
#define TNI_API_HEADER_TRAVERSALBASE
// Generated API for game version 0.10.7
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct TraversalBase : public Node {
	using Node::Node;

	constexpr TraversalBase(Node base) : Node{base} {}
	constexpr TraversalBase(uint64_t addr) : Node{addr} {}
	constexpr TraversalBase(Object obj) : TraversalBase{obj.address()} {}
	TraversalBase(Variant variant) : TraversalBase{variant.as_object().address()} {}

	enum Context : int64_t {  // NOTE: You should recompile your mod if this enum changes!
		SRC_CONTROLLER = 0,
		BANDWIDTH_USED = 1,
		CONSUMED_TARGET = 2,
		DST_FQDN = 3,
		DST_LADDR = 4,
		TEST = 5,
		INDEX = 6,
		TTL = 7,
	};

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

inline NetworkPacketRoot TraversalBase::make_packet_root() { return NetworkPacketRoot(operator()("make_packet_root").as_object().address()); }
inline Variant TraversalBase::make_traversal_packet(NetworkPacketRoot proot) { return operator()("make_traversal_packet", proot); }
inline void TraversalBase::tick() { voidcall("tick"); }
inline String TraversalBase::colorize_description(String ds) { return operator()("colorize_description", ds); }
inline void TraversalBase::start() { voidcall("start"); }
inline void TraversalBase::stop() { voidcall("stop"); }
inline void TraversalBase::uninstall() { voidcall("uninstall"); }
inline void TraversalBase::install(Variant _install_opts) { voidcall("install", _install_opts); }
inline bool TraversalBase::process_network_packet(PacketControlModule pktctl, Variant packet) { return operator()("process_network_packet", pktctl, packet); }
inline bool TraversalBase::is_pkt_for_self(Variant packet) { return operator()("is_pkt_for_self", packet); }

#endif
