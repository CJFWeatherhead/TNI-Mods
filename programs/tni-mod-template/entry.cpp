/*
    Tower Networking Inc - Modding Template
    
    This template demonstrates common use cases for writing mods in C/C++.
    It shows how to:
    - Register callback functions for various game events
    - Access game world state and properties
    - Create UI elements (dialogs)
    - Handle player input
    - Interact with devices and game objects
    
    Documentation:
    - C++ Examples: https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cppexamples/
    - C++ API Reference: https://libriscv.no/docs/host_langs/godot_integration/godot_docs/cppapi
    - Main Repository: https://github.com/CJFWeatherhead/TNI-Mods
*/

#include <api.hpp>
#include "tower.hpp"

// System call for creating nodes dynamically
EXTERN_SYSCALL(uint64_t, sys_node_create, Node_Create_Shortlist, const char *, size_t, const char *, size_t);

// Global mod API handles
static Mod mod = Mod(0);
static ModApiV1 api_v1 = ModApiV1(0);

// This should be called at the entrance of any calls into the mod
// e.g., callbacks like `on_mod_load` and any callables given to Godot
inline void fetch_mod_api() {
	mod = get_node<Mod>();
	api_v1 = mod.api_v1();
}

// Example: Persistent variable across function calls
static int somevar;

// Example function demonstrating usage of the game API
void print_scenario_name() {
	std::optional<GameWorld> gw = api_v1.get_game_world();
	if (!gw) return;
	
    String scenario_name = gw.value().scenario_name();
    printf("Current scenario: %s\n", scenario_name.utf8().c_str());
}

// Callback: Called immediately after the mod is loaded (after main())
static Variant on_mod_load() {
	fetch_mod_api();
	printf("Loaded tni-mod-template\n");
	return Nil;
}

// Callback: Called when all mods have been loaded
static Variant on_engine_load() {
	fetch_mod_api();
	printf("All mods have been loaded...\n");

	// Example: Create and show a dialog window
	std::string classname = "AcceptDialog";
	std::string path = "";
	AcceptDialog diag = sys_node_create(Node_Create_Shortlist::CREATE_CLASSDB, classname.data(), classname.size(), path.data(), path.size());
	diag.title() = "Testing a dialog.";
	diag.dialog_text() = "Hello from a TNI mod!";
	
	// Create a callback to close the dialog
	Callable close_fn = Callable::Create<Variant(AcceptDialog)>([](AcceptDialog diag) -> Variant {
		diag.queue_free();
		return Nil;
	}, Variant(diag));
	
	// Connect the close callback to dialog signals
	// Note: godot-sandbox doesn't have a type for Signal yet
	diag.get("confirmed")("connect", close_fn);
	diag.get("canceled")("connect", close_fn);
	
	// Add dialog to scene tree and display it
	get_node().add_child(diag);
	diag.popup_centered();

	return Nil;
}

// Callback: Called every game tick
static Variant on_game_tick(double delta) {
	fetch_mod_api();
	// Called every frame - be careful with performance here!
	// delta = time since last tick in seconds
	return Nil;
}

// Callback: Called when player input is received
static Variant on_player_input(InputEvent event) {
	fetch_mod_api();
	
	// Example: Handle keyboard input
    if (event.get_class() == "InputEventKey") {
        InputEventKey* key = reinterpret_cast<InputEventKey*>(&event);
        
        // Check for spacebar press
        if (key->is_pressed() && key->get_keycode() == 32) {
            printf("SPACEBAR pressed! Counter: %d\n", somevar);
            somevar += 1;
			print_scenario_name();
        } else if (!key->is_pressed() && key->get_keycode() == 32) {
            printf("Spacebar released\n");
        }
    }
	
	return Nil;
}

// Callback: Called when the game state is ready (game loaded/started)
static Variant on_game_state_ready() {
	fetch_mod_api();
	printf("Game state is ready!\n");
    print_scenario_name();
	return Nil;
}

// Callback: Called when the game host's end-of-day occurs
static Variant on_game_host_eod() {
	fetch_mod_api();
	// Useful for daily calculations, reports, or periodic tasks
	return Nil;
}

// Callback: Called when a device is spawned in the game
static Variant on_device_spawned(DeviceUnit device) {
	fetch_mod_api();
	// Access device properties here
	// Example: device.product_name(), device.device_hardware_class, etc.
	return Nil;
}

// Example cleanup function
static void test() {
	printf("Mod cleanup at exit\n");
}

int main() {
    // Enable line buffering for stdout to match TNI mod output buffering
    setvbuf(stdout, NULL, _IOLBF, BUFSIZ);

	// Register all callback functions with the game
	// Format: ADD_API_FUNCTION(function_name, args, return_type, description)
	ADD_API_FUNCTION(on_mod_load, "", "", "Called immediately after the mod is loaded (after main())");
	ADD_API_FUNCTION(on_engine_load, "", "", "Called when all mods have been loaded");
	ADD_API_FUNCTION(on_game_state_ready, "", "", "Called when the game is ready");
	ADD_API_FUNCTION(on_game_host_eod, "", "", "Called when the end-of-day occurs on the host");
	ADD_API_FUNCTION(on_game_tick, "", "", "Called every game tick");
	ADD_API_FUNCTION(on_player_input, "", "", "Called when player input");
	ADD_API_FUNCTION(on_device_spawned, "", "", "Called when device spawned");

	// Register cleanup handler
	atexit(test);

	// Halt execution - the game will call registered functions as needed
	halt();
}
