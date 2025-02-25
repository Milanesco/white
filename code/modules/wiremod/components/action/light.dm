/**
 * # Light Component
 *
 * Emits a light of a specific brightness and colour. Requires a shell.
 */
/obj/item/circuit_component/light
	display_name = "Светодиод"
	desc = "Компонент, который излучает свет определенной яркости и цвета. Для использования требуется оболочка."

	/// The colours of the light
	var/datum/port/input/red
	var/datum/port/input/green
	var/datum/port/input/blue

	/// The brightness
	var/datum/port/input/brightness

	/// Whether the light is on or not
	var/datum/port/input/on

	var/max_power = 5
	var/min_lightness = 0.4
	var/shell_light_color

/obj/item/circuit_component/light/get_ui_notices()
	. = ..()
	. += create_ui_notice("Maximum Brightness: [max_power]", "orange", "lightbulb")

/obj/item/circuit_component/light/populate_ports()
	red = add_input_port("Красный", PORT_TYPE_NUMBER)
	green = add_input_port("Зелёный", PORT_TYPE_NUMBER)
	blue = add_input_port("Синий", PORT_TYPE_NUMBER)
	brightness = add_input_port("Яркость", PORT_TYPE_NUMBER)

	on = add_input_port("On", PORT_TYPE_NUMBER)

/obj/item/circuit_component/light/register_shell(atom/movable/shell)
	. = ..()
	trigger_component()

/obj/item/circuit_component/light/unregister_shell(atom/movable/shell)
	shell.set_light_on(FALSE)
	return ..()

/obj/item/circuit_component/light/pre_input_received(datum/port/input/port)
	brightness.set_value(clamp(brightness.value || 0, 0, max_power))
	red.set_value(clamp(red.value, 0, 255))
	blue.set_value(clamp(blue.value, 0, 255))
	green.set_value(clamp(green.value, 0, 255))
	var/list/hsl = rgb2hsl(red.value || 0, green.value || 0, blue.value || 0)
	var/list/light_col = hsl2rgb(hsl[1], hsl[2], max(min_lightness, hsl[3]))
	shell_light_color = rgb(light_col[1], light_col[2], light_col[3])

/obj/item/circuit_component/light/input_received(datum/port/input/port)
	if(parent.shell)
		set_atom_light(parent.shell)

/obj/item/circuit_component/light/proc/set_atom_light(atom/movable/target_atom)
	// Clamp anyways just for safety
	var/bright_val = min(max(brightness.value || 0, 0), max_power)

	target_atom.set_light_power(bright_val)
	target_atom.set_light_range(bright_val)
	target_atom.set_light_color(shell_light_color)
	target_atom.set_light_on(!!on.value)
