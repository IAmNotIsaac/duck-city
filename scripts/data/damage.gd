class_name Damage


enum DamageType {
	Indiscriminant
}


var damage_type : DamageType
var amount : float


func _init(damage_type_ : DamageType, amount_ : float) -> void:
	damage_type = damage_type_
	amount = amount_
