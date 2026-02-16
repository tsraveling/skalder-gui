extends Control

@onready var skald_engine: SkaldEngine = $SkaldEngine
@onready var log_text: RichTextLabel = %LogText
@onready var state_list: VBoxContainer = %StateList
@onready var continue_label: Label = %ContinueLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var input_container: VBoxContainer = %InputContainer

const VALUE_INPUT_SCENE = preload("res://scenes/ValueInput.tscn")

const SPEAKER_COLORS = [
	Color("#da70d6"),
	Color("#6495ed"),
	Color("#90ee90"),
	Color("#ffd700"),
	Color("#ff6347"),
	Color("#87ceeb"),
	Color("#dda0dd"),
]

var _speaker_color_map: Dictionary = {}
var _next_color_idx: int = 0
var _response_input: ValueInputField


func _ready() -> void:
	_response_input = VALUE_INPUT_SCENE.instantiate()
	input_container.add_child(_response_input)
	_add_placeholder_state()
	_add_placeholder_logs()
	show_continue()


# -- Log view --

func add_attributed_log(speaker: String, content: String) -> void:
	var col := _get_speaker_color(speaker)
	var hex := col.to_html(false)
	log_text.append_text(
		"\n[color=#%s][b]%s:[/b][/color]\n[indent]%s[/indent]\n" % [hex, speaker, content]
	)


func add_narrative_log(content: String) -> void:
	log_text.append_text("\n%s\n" % content)


func add_system_log(content: String) -> void:
	log_text.append_text("\n[color=#888888]%s[/color]\n" % content)


func add_error_log(content: String) -> void:
	log_text.append_text("\n[color=#ff4444]%s[/color]\n" % content)


# -- Response area --

func show_continue() -> void:
	continue_label.visible = true
	choices_container.visible = false
	input_container.visible = false


func show_choices(options: Array) -> void:
	continue_label.visible = false
	choices_container.visible = true
	input_container.visible = false
	for child in choices_container.get_children():
		child.queue_free()
	for i in options.size():
		var label := Label.new()
		label.text = "%d. %s" % [i + 1, options[i]]
		choices_container.add_child(label)


func show_input() -> void:
	continue_label.visible = false
	choices_container.visible = false
	input_container.visible = true


# -- State panel --

func add_state_entry(key: String, value: Variant) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var key_label := Label.new()
	key_label.text = key
	key_label.custom_minimum_size.x = 100
	key_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	row.add_child(key_label)

	var vi: ValueInputField = VALUE_INPUT_SCENE.instantiate()
	vi.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(vi)

	state_list.add_child(row)
	vi.set_value(value)


func clear_state() -> void:
	var children := state_list.get_children()
	for i in range(2, children.size()):
		children[i].queue_free()


# -- Speaker colors --

func _get_speaker_color(speaker: String) -> Color:
	if speaker not in _speaker_color_map:
		_speaker_color_map[speaker] = SPEAKER_COLORS[_next_color_idx % SPEAKER_COLORS.size()]
		_next_color_idx += 1
	return _speaker_color_map[speaker]


# -- Placeholders --

func _add_placeholder_state() -> void:
	add_state_entry("player_name", "Alice")
	add_state_entry("health", 100)
	add_state_entry("speed", 1.5)
	add_state_entry("is_alive", true)
	add_state_entry("quest_item", null)


func _add_placeholder_logs() -> void:
	add_system_log("Module loaded: intro.ska")
	add_narrative_log("The sun set slowly over the distant mountains, casting long shadows across the valley.")
	add_attributed_log("mia", "Hello there. How are you doing today?")
	add_attributed_log("bob", "I'm doing well, thanks for asking.")
	add_narrative_log("A cool breeze swept through the trees.")
	add_error_log("Warning: undefined variable 'x'")
	add_system_log("State saved.")
