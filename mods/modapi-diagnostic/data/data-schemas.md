# TNI Data File Schemas

Reference schemas for the JSON data files in this directory. These files document the game objects, mechanics and catalog of **Tower Networking Inc.** (game version 0.10.11+).

Each file can be populated/updated by running the corresponding `extract_*` console command in the modapi-diagnostic mod (press `~` to open the debug console), then merging the extracted JSON with the existing file.

---

## Extraction Workflow

1. Load a game with the `modapi-diagnostic` mod enabled
2. Press `~` to open the debug console
3. Run `extract_all` (or individual commands below)
4. Extracted JSON is printed to logs and optionally written to `data/extracted-*.json`
5. Give the extracted JSON plus the existing `data/*.json` file to an LLM with the instruction: _"Merge the extracted data into the existing JSON file. Add new entries, update incomplete fields, preserve manually-added fields (notes, corrections, contributors)."_

| Command | Output File | Description |
|---------|------------|-------------|
| `extract_store_catalog` | `tni-store.json` | Merchants, device listings, hardware specs |
| `extract_programs` | `tni-programs.json` | Installable/running programs |
| `extract_proposals` | `tni-proposals.json` | Proposal system state |
| `extract_traffic_types` | `tni-traffic-types.json` | Network traffic classes |
| `extract_cli_commands` | `tni-cli-commands.json` | Terminal routines, autocomplete |
| `extract_all` | All of the above | Runs all 5 extractions |

---

## Common Envelope

Every extracted JSON file uses a common wrapper:

```json
{
  "_meta": {
    "game": "Tower Networking Inc.",
    "dataset": "<dataset-name>",
    "version": "<semver>",
    "last_updated": "<ISO date>",
    "description": "<human-readable purpose>",
    "sources": [{ "name": "...", "notes": "..." }],
    "contributors": ["..."],
    "corrections": [{ "version": "...", "correction": "...", "reported_by": "..." }],
    "future_additions": [{ "suggestion": "...", "details": "..." }]
  },
  ...dataset-specific fields...
}
```

The `_meta` block is manually maintained. Extraction output uses `_meta.llm_instructions` to guide merge behavior.

---

## 1. tni-store.json — Store Catalog

### Purpose
Complete catalog of purchasable items from all in-game merchants (D-Market2, Barracks and Sons, Tenabolt Retail, etc.).

### Top-level structure
```
merchants[]              — Array of merchant objects
device_specs[]           — Array of device hardware specs (from placed devices)
device_hardware_class_enum — Map of integer → hardware class name
```

### Merchant Schema
| Field | Type | Description |
|-------|------|-------------|
| `display_name` | string | Merchant name |
| `description` | string | Merchant description |
| `price_multiplier` | number | Price scaling factor |
| `price_add_constant` | integer | Fixed price addition |
| `warranty_multiplier` | number | Warranty scaling factor |
| `warranty_add_constant` | integer | Fixed warranty addition |
| `restock_period` | number | Days between restocks |
| `restock_mode` | integer | Restock behavior mode |
| `entry_max_stocks` | integer | Default max stock per listing |
| `listings[]` | array | Device listings |

### Device Listing Schema
| Field | Type | Description |
|-------|------|-------------|
| `listing_title` | string | Product name as shown in store |
| `description` | string | Listing description |
| `price` | integer | Purchase price |
| `warranty_period` | integer | Warranty in days |
| `stock` | integer | Current stock |
| `max_stock` | integer | Maximum stock |
| `max_stock_override` | integer | Override for max stock |
| `available` | boolean | Currently purchasable |
| `previous_availability` | boolean | Was previously available |
| `listed_on_day` | integer | Day first listed |
| `delisted_on_day` | integer | Day removed (-1 if active) |
| `allowed_variant` | integer | 0=none, 1=cable color |
| `device_scene_path` | string | Internal scene resource path |

### Device Spec Schema (from placed devices)
| Field | Type | Description |
|-------|------|-------------|
| `product_name` | string | Device name |
| `device_hardware_class` | integer | Hardware class enum value |
| `hardware_class_name` | string | Human-readable class name |
| `description` | string | Device description |
| `price` | integer | Base price |
| `recycle_price` | integer | Recycle value |
| `base_warranty_days` | integer | Base warranty period |
| `bw_per_second` | number | Bandwidth per second |
| `reliability_flt` | number | Reliability factor |
| `mount_type` | integer | 0=NA, 1=R500, 2=R930, 3=R630 |
| `installed_cpu` | integer | CPU units |
| `installed_mem` | integer | Memory units |
| `installed_sto` | integer | Storage units |
| `installed_nbw` | integer | Network bandwidth units |
| `power_load` | integer | Power consumption (watts) |
| `port_count` | integer | Number of network ports |
| `is_network_switch` | boolean | Switch capability |
| `is_network_router` | boolean | Router capability |
| `is_network_middlebox` | boolean | Middlebox (firewall/tap) |
| `is_vlan_enabled` | boolean | VLAN support |
| `is_ha_enabled` | boolean | High-availability support |
| `installed_programs[]` | array | Programs currently installed |
| `charge_capacity` | number | UPS charge capacity |
| `surge_blocker` | boolean | Surge protection |

### Hardware Class Enum
| Value | Name |
|-------|------|
| 0 | DEFAULT |
| 1 | NETWORK_SWITCH |
| 2 | NETWORK_ROUTER |
| 3 | NETWORK_TAP |
| 4 | NETWORK_FIREWALL |
| 5 | MEDIA_LINE_SIMPLEX |
| 6 | MEDIA_LINE_DUPLEX |
| 7 | COMPUTE_SERVER |
| 8 | DISPLAY_MONITOR |
| 9 | DEBUGGER |
| 10 | LOAD_TESTER |
| 11 | POWER_EXPANSION |
| 12 | DECENTRO_RIGS |
| 13 | SURGE_PROTECTOR |
| 14 | UPS |
| 15 | INERT |
| 16 | CCTV |
| 17 | PHONE |
| 18 | PRINTER |
| 19 | NETWORK_LOAD_BALANCER |
| 20 | NETWORK_STORAGE |

### Existing Manual Fields (preserve on merge)
The existing `tni-store.json` organizes devices by category (`network_switches`, `servers`, `routers`, etc.) with manually-curated fields like `vendor`, `media`, `managed`, `vlan_support`, `traversals_per_tick`, `cpu_cycle`, `notes`, `compatible_programs`, `sata_slots`. These should be preserved; extraction output provides raw API data that can fill in gaps.

---

## 2. tni-programs.json — Programs

### Purpose
Catalog of all installable server programs with resource requirements, I/O, and dependencies.

### Top-level structure
```
programs[]                    — Array of program objects
programs_found_count          — Total programs discovered
controller_modifiers_enum     — Map of integer → modifier name
```

### Program Schema
| Field | Type | Description |
|-------|------|-------------|
| `release_name` | string | Unique program identifier |
| `description` | string | In-game description |
| `cpu_load` | integer | CPU cost while running |
| `code_size` | integer | Code memory footprint |
| `stack_size` | integer | Stack memory footprint |
| `data_size` | integer | Data memory footprint |
| `install_size` | integer | Disk space required |
| `pkt_processing_priority` | integer | Packet processing order |
| `is_running` | boolean | Currently running (snapshot) |
| `found_on_device` | string | Device where discovered |
| `found_on_hw_class` | string | Hardware class of host device |
| `found_on_user` | string | User where discovered (if user program) |
| `behavior_type` | string | `behaviors` / `hosting_behaviors` / `public_client_behaviors` |
| `modifiers[]` | array of string | Controller modifier flags |
| `application_unlocks[]` | array of string | Features this program unlocks |
| `required_hardware_device[]` | array of string | Required hardware |
| `traffic_class` | string | Network traffic type (user programs) |
| `traffic_weight` | integer | Traffic bandwidth weight |
| `satiety_weight` | number | User satiety contribution |

### Controller Modifiers Enum
| Value | Name |
|-------|------|
| 0 | ALLOW_REMOTE_DEBUGGING |
| 1 | ALLOW_PACKET_SWITCHING |
| 2 | ALLOW_PACKET_ROUTING |
| 3 | ALLOW_PACKET_INSPECTION |
| 4 | ALLOW_PACKET_FILTERING |
| 5 | ALLOW_DOMAIN_QUERYING |
| 6 | ALLOW_REMOTE_HOST_CONFIGURATION |
| 7 | ALLOW_HIGH_AVAILABILITY_SETUP |
| 8 | ALLOW_DECENTRO_STORAGE |
| 9 | ALLOW_DECENTRO_TRADING |
| 10 | ALLOW_VLAN_TAGGING |
| 11 | ALLOW_TRAFFIC_SPLITTING |
| 12 | ALLOW_STP_PORT_CONTROL |
| 13 | ALLOW_PACKET_TRANSLATION |

### Existing Manual Fields (preserve on merge)
The existing file uses `type` (producer/converter/data storage/firmware), `input`/`output` with `uses[]`, `amount`, `rate`, `target`, `requires`, `stack_limit`. Also `program_categories` and `use_types` indexes. These are manually curated and should be preserved.

---

## 3. tni-proposals.json — Proposals

### Purpose
Catalog of all in-game proposals with prerequisites, costs, effects, and unlock relationships.

### Top-level structure
```
proposals[]           — Array of proposal objects
proposals_count       — Total proposals
controller            — PropModController metadata
```

### Proposal Schema
| Field | Type | Description |
|-------|------|-------------|
| `proposal_name` | string | Display name |
| `description` | string | Full description text |
| `lore` | string | Flavor text |
| `submitted` | boolean | Has been purchased/applied |
| `locked` | boolean | Locked (reserved for future) |
| `can_be_proposed` | boolean | Currently eligible to appear |
| `is_active_proposal` | boolean | Currently showing as option |
| `can_be_proposed_beginning` | integer | Earliest day to appear |
| `force_once_on_day` | integer | Force appearance on this day |
| `proposed_on` | integer | Day it was proposed |
| `weight` | integer | Selection weight |
| `depends_on` | string | Prerequisite proposal name |
| `adhoc_requirements_met` | boolean | Dynamic requirements check |

### PropMod Controller Schema
| Field | Type | Description |
|-------|------|-------------|
| `batch_day_interval` | integer | Days between proposal batches |
| `proposals_per_batch` | integer | Number of proposals per batch |
| `reroll_fee` | integer | Cost to reroll proposals |
| `current_proposal_count` | integer | Active proposals |
| `history_proposal_count` | integer | Total proposals ever seen |
| `locked_proposal_count` | integer | Currently locked count |

### Existing Manual Fields (preserve on merge)
The existing file adds `id`, `category`, `cost` (integer or array for scaling), `repeatable`, `max_levels`, `prerequisites` (detailed conditions), `unlocks` (routines/programs/merchants), `effects[]`, `mutual_exclusivity_notes`, `starting_proposals`. These are manually curated.

---

## 4. tni-traffic-types.json — Network Traffic Types

### Purpose
Network traffic types for firewall rules, router configuration, and traffic analysis.

### Top-level structure
```
observed_traffic_types[]   — Traffic types seen in live game
observed_count             — Count of observed types
known_reference_types[]    — Static reference table of all known types
```

### Observed Traffic Type Schema
| Field | Type | Description |
|-------|------|-------------|
| `traffic_class` | string | Traffic identifier (e.g., `tcp/80`, `udp/53`) |
| `first_seen_on` | string | Device/port where first observed |

### Known Reference Type Schema
| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Traffic class string |
| `protocol` | string | `tcp`, `udp`, or `icmp` |
| `port` | integer/null | Port number (null for ranges/ICMP) |
| `name` | string | Human-readable name |
| `category` | string | Category (utility/management/infrastructure/consumer/malicious/routing/streaming/voip/database/decentro) |

### Existing Manual Fields (preserve on merge)
The existing file adds `description`, `used_by[]`, `notes`, `port_start`/`port_end` for ranges, and `categories` index. These are manually curated.

---

## 5. tni-cli-commands.json — CLI Commands

### Purpose
Reference for in-game terminal (netsh) commands, syntax, and examples.

### Top-level structure
```
terminal_routines[]           — Registered command routines
terminal_routines_count       — Count of routines found
autocomplete_candidates[]     — Registered autocomplete strings
registered_domains[]          — Registered domain names
shell_found                   — Whether a NetShell was accessible
```

### Terminal Routine Schema
| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Command name |
| `class` | string | Godot class name |
| `enabled` | boolean | Whether the routine is enabled |

### Existing Manual Fields (preserve on merge)
The existing file has rich manually-curated data: `shell_shortcuts`, `commands` with `description`, `subcommands`, `syntax`, `examples[]`, `traffic_types`, `device_types`, `notes`, `aliases`, `schedules`. The extraction provides the _list_ of available routines; the detailed syntax/examples are manual.

---

## Merge Guidelines for LLMs

When merging extracted data with existing files:

1. **Never delete** existing entries unless explicitly confirmed as incorrect
2. **Preserve** all `_meta` fields (contributors, corrections, sources, future_additions)
3. **Preserve** manually-added fields (notes, examples, syntax, categories, etc.)
4. **Add** new entries that appear in extraction but not in the existing file
5. **Update** fields where extraction provides a concrete value and existing has a placeholder (e.g., `"example"`, `null`, or missing)
6. **Skip** fields marked `"<unavailable>"` in extraction output — these couldn't be read from the API
7. **Cross-reference** `device_specs` with store listings to fill in `cpu`, `memory`, `storage`, `firmware`, `power_w` etc.
8. **Keep** the existing file's organizational structure (category arrays, grouped objects)
