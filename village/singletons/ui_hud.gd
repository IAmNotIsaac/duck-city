extends Control


@onready var _money_label := $MoneyLabel
@onready var _interaction_prompts := $ScrollContainer/Prompts


func _ready() -> void:
	_update_money_label(Stats.money)
	_update_interaction_prompts(Stats.interact_prompts)
	_update_interaction_index(Stats.interaction_index)
	
	Stats.money_changed.connect(_update_money_label)
	Stats.interact_prompts_changed.connect(_update_interaction_prompts)
	Stats.interaction_index_changed.connect(_update_interaction_index)


func _update_money_label(v : int) -> void:
	_money_label.text = str("Money: $%s" % v)


func _update_interaction_prompts(prompts : Array[InteractionData]) -> void:
	for c in _interaction_prompts.get_children():
		c.queue_free()
	
	var i := 0
	for p in prompts:
		var label := Label.new()
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.text = p.details
		label.label_settings = LabelSettings.new()
		label.label_settings.font_color = Color.YELLOW if i == Stats.interaction_index else Color.WHITE
		
		_interaction_prompts.add_child(label)
		
		i += 1
	
	Stats.interaction_index = Stats.interaction_index


func _update_interaction_index(interaction_index : int) -> void:
	var prompts : Array[Node] = _interaction_prompts.get_children()
	prompts.reverse()
	if len(prompts) > 0:
		for prompt in prompts:
			prompt.label_settings.font_color = Color.WHITE
		prompts[interaction_index].label_settings.font_color = Color.YELLOW
