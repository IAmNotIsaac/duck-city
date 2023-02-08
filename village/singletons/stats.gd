extends Node


signal money_changed(new_value : int)
signal interact_prompts_changed(interaction_data : Array[InteractionData])
signal interaction_index_changed(interaction_index : int)


var money := 8000:
	set(v):
		money = v
		money_changed.emit(v)


var interact_prompts : Array[InteractionData] = []

func add_interact_prompt(interaction_data : InteractionData) -> void:
	interact_prompts.append(interaction_data)
	interact_prompts_changed.emit(interact_prompts)

func erase_interact_prompt(interaction_data : InteractionData) -> void:
	interact_prompts.erase(interaction_data)
	interact_prompts_changed.emit(interact_prompts)


var interaction_index : int = 0:
	set(v):
		interaction_index = clamp(v, 0, len(interact_prompts) - 1)
		interaction_index_changed.emit(interaction_index)
