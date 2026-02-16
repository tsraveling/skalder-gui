extends Control

@onready var skald_engine: SkaldEngine = $SkaldEngine
@onready var prompt_label: Label = %PromptLabel
@onready var prompt_input: ValueInputField = %PromptInput
@onready var log_text: RichTextLabel = %LogText
@onready var state_list: VBoxContainer = %StateList
@onready var continue_label: Label = %ContinueLabel
@onready var choices_container: VBoxContainer = %ChoicesContainer
@onready var input_container: VBoxContainer = %InputContainer
@onready var no_file_label: Label = %NoFileLabel
@onready var file_dialog: FileDialog = $FileDialog
@onready var file_menu: PopupMenu = $RootLayout/MenuBar/File

enum ExpectedResponse {
CONTINUE,
CHOICE,
INPUT,
ERROR,
DONE,
NO_FILE
}

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
var _file_loaded: bool = false
var _expected_response: ExpectedResponse = ExpectedResponse.CONTINUE
var _current_options: Array = []

# SECTION: SKALD ENGINE INTEGRATION

# TODO: Put Skald here!

func start_module(path: String) -> void:
	skald_engine.load(path)
	var response = skald_engine.start()
	handle_response(response)

func query_to_string(q: SkaldQuery) -> String:
	var ret = "QUERY: " if q.expects_response else "CALL: "
	ret += q.method
	for arg in q.args:
		ret += " (" + arg + ")"
	return ret

func handle_response(response: Variant):

	# Handle flat method calls
	# Note: The reason we still answer a normal method call like this is that we can optionally make
	# it blocking. For instance we could e.g. handle a :play_animation method and not continue the text
	# until the animation finishes playing.
	while response is SkaldQuery && !(response as SkaldQuery).expects_response:
		# This is how you answer a method call that does not expect a response:
		add_system_log(query_to_string(response))
		response = skald_engine.answer(null)

	if response is SkaldContent:
		var content := response as SkaldContent
		if content.attribution != "":
			add_attributed_log(content.attribution, content.text)
		else:
			add_narrative_log(content.text)
		if content.options.size() > 0:
			_current_options = content.options
			show_choices(content.options)
		else:
			show_continue()
		pass
	elif response is SkaldQuery:
		var query := response as SkaldQuery
		var prompt_string := query_to_string(query)
		add_system_log(prompt_string)
		show_input(prompt_string)
		pass
	elif response is SkaldExit:
		var exit := response as SkaldExit
		add_system_log("MODULE EXIT")
		show_continue()
		pass
	elif response is SkaldGoModule:
		var go_module := response as SkaldGoModule
		add_system_log("MODULE GO: " + go_module.module_path)
		show_continue()
		pass
	elif response is SkaldError:
		var error := response as SkaldError
		add_error_log(error.message)
		show_continue()
		pass
	elif response is SkaldEnd:
		var end := response as SkaldEnd
		show_continue()
		pass

func handle_answer(val: Variant):
	add_system_log("ANSWERED: " + val)
	handle_response(skald_engine.answer(val))

# SECTION: UI AND INFRASTRUCTURE

func _on_file_loaded(path: String) -> void:
	_file_loaded = true
	no_file_label.visible = false
	log_text.clear()
	add_system_log("Loaded: " + path)
	start_module(path)

func _process(_delta: float) -> void:
	match _expected_response:
		ExpectedResponse.CONTINUE:
			if Input.is_action_just_pressed("continue"):
				var response = skald_engine.act(0)
				handle_response(response)
		ExpectedResponse.CHOICE:
			for i in range(9):
				if Input.is_action_just_pressed("pick_%d" % [i + 1]):
					if i < _current_options.size() and (_current_options[i] as SkaldOption).is_available:
						_on_choice_pressed(i)
					break

func _ready() -> void:

	# Menu setup
	file_menu.add_item("Load...", 0)
	file_menu.add_item("Exit", 1)
	file_menu.id_pressed.connect(_on_file_menu_pressed)
	file_dialog.file_selected.connect(_on_file_selected)

	_add_placeholder_state()
	_add_placeholder_logs()

	# Prompt for file on launch
	file_dialog.popup_centered()


func _on_file_menu_pressed(id: int) -> void:
	match id:
		0: file_dialog.popup_centered()
		1: get_tree().quit()


func _on_file_selected(path: String) -> void:
	_on_file_loaded(path)


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

func set_expected_response(expected: ExpectedResponse):
	_expected_response = expected
	no_file_label.visible = expected == ExpectedResponse.NO_FILE
	continue_label.visible = expected == ExpectedResponse.CONTINUE
	choices_container.visible = expected == ExpectedResponse.CHOICE
	input_container.visible = expected == ExpectedResponse.INPUT
	# TODO: Handle other expected response types.

func show_continue() -> void:
	set_expected_response(ExpectedResponse.CONTINUE)


func show_choices(options: Array) -> void:
	for child in choices_container.get_children():
		child.queue_free()
	set_expected_response(ExpectedResponse.CHOICE)
	for i in options.size():
		var opt := options[i] as SkaldOption
		if opt.is_available:
			var button := Button.new()
			button.text = "%d. %s" % [i + 1, opt.text]
			button.pressed.connect(_on_choice_pressed.bind(i))
			choices_container.add_child(button)
		else:
			var label := RichTextLabel.new()
			label.fit_content = true
			label.bbcode_enabled = true
			label.scroll_active = false
			label.text = "[center][s][color=#888888]%d. %s[/color][/s][/center]" % [i + 1, opt.text]
			choices_container.add_child(label)


func _on_choice_pressed(index: int) -> void:
	var response = skald_engine.act(index)
	handle_response(response)


func show_input(prompt: String) -> void:
	set_expected_response(ExpectedResponse.INPUT)



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


func _on_prompt_button_pressed() -> void:
	var val = prompt_input.get_value()
	handle_answer(val)

func _on_prompt_input_value_submitted(value: Variant) -> void:
	handle_answer(value)
