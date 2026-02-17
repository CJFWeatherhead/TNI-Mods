#ifndef TNI_API_HEADER_SEMVERVERSIONCOMPARATORUNARY
#define TNI_API_HEADER_SEMVERVERSIONCOMPARATORUNARY
// Generated API for game version 0.10.7
// If any constants or enum's change between versions, a rebuild of your mod with updated headers may be required!

#include <generated_api.hpp>
#include "structs.hpp"

struct SemVerVersionComparatorUnary : public RefCounted {
	using RefCounted::RefCounted;

	constexpr SemVerVersionComparatorUnary(RefCounted base) : RefCounted{base} {}
	constexpr SemVerVersionComparatorUnary(uint64_t addr) : RefCounted{addr} {}
	constexpr SemVerVersionComparatorUnary(Object obj) : SemVerVersionComparatorUnary{obj.address()} {}
	SemVerVersionComparatorUnary(Variant variant) : SemVerVersionComparatorUnary{variant.as_object().address()} {}


	PROPERTY(op, int64_t);
	PROPERTY(operand, RefCounted);

	inline String to_range_string();
	inline String op_string();
	inline bool check_version(SemVerVersion version);
	inline RefCounted parse(String raw);
};

#include "SemVerVersion.hpp"

inline String SemVerVersionComparatorUnary::to_range_string() { return operator()("to_range_string"); }
inline String SemVerVersionComparatorUnary::op_string() { return operator()("op_string"); }
inline bool SemVerVersionComparatorUnary::check_version(SemVerVersion version) { return operator()("check_version", version); }
inline RefCounted SemVerVersionComparatorUnary::parse(String raw) { return RefCounted(operator()("parse", raw).as_object().address()); }

#endif
