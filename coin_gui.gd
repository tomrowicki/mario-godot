extends CanvasLayer


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label.text = "Coins: " + str(Global.total_coins)
