class_name CwCombat
extends RefCounted
## Provisional assault formula (design doc "Combat"). Pure: mutates nothing.
## power = troops x (morale/100) x factor; victory margin sets both losses.


static func assault(army: CwArmy, city: CwCity) -> Dictionary:
	var out := {"won": false, "captured": false, "att_losses": 0, "def_losses": 0}
	var def_power := city.troops * (city.morale / 100.0) * city.wall_factor
	if def_power <= 0.0:
		out["won"] = true
		out["captured"] = true
		return out

	var att_power := army.troops * (army.morale / 100.0) * army.general_combat_factor
	var ratio := att_power / def_power
	var loss_reduction := clampf(army.general_loss_reduction, 0.0, 1.0)
	if ratio >= 1.0:
		out["won"] = true
		out["def_losses"] = _clamped_loss(city.troops * clampf(0.3 * ratio, 0.3, 1.0),
				city.troops)
		out["att_losses"] = _clamped_loss(army.troops * clampf(0.2 / ratio, 0.05, 0.2)
				* (1.0 - loss_reduction), army.troops)
	else:
		out["att_losses"] = _clamped_loss(army.troops
				* clampf(0.25 / maxf(ratio, 0.1), 0.25, 0.5)
				* (1.0 - loss_reduction), army.troops)
		out["def_losses"] = _clamped_loss(city.troops * 0.1 * ratio, city.troops)
	return out


static func _clamped_loss(value: float, max_loss: int) -> int:
	return mini(maxi(_loss_int(value), 0), max_loss)


static func _loss_int(value: float) -> int:
	return int(value + 0.0001)
