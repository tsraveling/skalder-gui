class_name ValueInputField
extends HBoxContainer

signal value_submitted(value: Variant)

enum ValueType { UNDEFINED, INT, FLOAT, BOOLEAN, STRING }

@onready var type_select: OptionButton = $TypeSelect
@onready var text_input: LineEdit = $TextInput
@onready var bool_toggle: CheckButton = $BoolToggle

var current_type := ValueType.STRING


func _ready() -> void:
	type_select.add_item("Undefined", ValueType.UNDEFINED)
	type_select.add_item("Int", ValueType.INT)
	type_select.add_item("Float", ValueType.FLOAT)
	type_select.add_item("Boolean", ValueType.BOOLEAN)
	type_select.add_item("String", ValueType.STRING)
	type_select.selected = current_type
	type_select.item_selected.connect(_on_type_changed)
	text_input.text_submitted.connect(_on_text_submitted)
	bool_toggle.toggled.connect(_on_bool_toggled)
	_update_input_visibility()


func _on_type_changed(index: int) -> void:
	current_type = type_select.get_item_id(index) as ValueType
	_update_input_visibility()


func _update_input_visibility() -> void:
	text_input.visible = current_type in [ValueType.INT, ValueType.FLOAT, ValueType.STRING]
	bool_toggle.visible = current_type == ValueType.BOOLEAN
	match current_type:
		ValueType.INT:
			text_input.placeholder_text = "integer"
		ValueType.FLOAT:
			text_input.placeholder_text = "float"
		ValueType.STRING:
			text_input.placeholder_text = "string"


func get_value() -> Variant:
	match current_type:
		ValueType.UNDEFINED:
			return null
		ValueType.INT:
			return text_input.text.to_int()
		ValueType.FLOAT:
			return text_input.text.to_float()
		ValueType.BOOLEAN:
			return bool_toggle.button_pressed
		ValueType.STRING:
			return text_input.text
	return null

func reset() -> void:
	set_value(null)


func set_value(value: Variant) -> void:
	if value == null:
		_select_type(ValueType.UNDEFINED)
	elif value is bool:
		_select_type(ValueType.BOOLEAN)
		bool_toggle.button_pressed = value
	elif value is int:
		_select_type(ValueType.INT)
		text_input.text = str(value)
	elif value is float:
		_select_type(ValueType.FLOAT)
		text_input.text = str(value)
	elif value is String:
		_select_type(ValueType.STRING)
		text_input.text = value
	_update_input_visibility()


func _select_type(type: int) -> void:
	current_type = type as ValueType
	for i in type_select.item_count:
		if type_select.get_item_id(i) == type:
			type_select.selected = i
			break


func _on_text_submitted(_text: String) -> void:
	value_submitted.emit(get_value())


func _on_bool_toggled(_pressed: bool) -> void:
	value_submitted.emit(get_value())
