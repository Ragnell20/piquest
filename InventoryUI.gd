extends CanvasLayer

var player = null
@onready var grid = %GridContainer
@onready var stats_label = %RichTextLabel


var current_focus_index = 0
var slots = []

@onready var navigate_sound = $SelectSound
@onready var select_sound = %NavigateSound

func _ready():
	visible = false
	if grid:
		grid.columns = 4


func set_player_reference(p):
	player = p

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
	
	if visible:
		if event.is_action_pressed("ui_right"):
			navigate_slots(1)
			play_navigate_sound()
		elif event.is_action_pressed("ui_left"):
			navigate_slots(-1)
			play_navigate_sound()
		elif event.is_action_pressed("ui_down"):
			navigate_slots(4)
			play_navigate_sound()
		elif event.is_action_pressed("ui_up"):
			navigate_slots(-4)
			play_navigate_sound()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			if slots.size() > 0 and current_focus_index < slots.size():
				play_select_sound()
				on_slot_clicked(current_focus_index)

func toggle_inventory():
	visible = !visible
	get_tree().paused = visible
	
	if visible:
		update_ui()
		current_focus_index = 0
		if slots.size() > 0:
			focus_slot(current_focus_index)
	else:
		stats_label.clear()
		slots.clear()

func navigate_slots(direction: int):
	if slots.size() == 0:
		return
	
	var old_index = current_focus_index
	current_focus_index += direction
	
	if current_focus_index < 0:
		current_focus_index = slots.size() - 1
	elif current_focus_index >= slots.size():
		current_focus_index = 0
	
	unfocus_slot(old_index)  # ← önce eskiyi unfocus et
	focus_slot(current_focus_index)

func focus_slot(index: int):
	if index < 0 or index >= slots.size():
		return
	var slot_data = slots[index]
	slot_data.front.visible = false
	slot_data.back.visible = true
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.25, 0.8)
	stylebox.border_color = Color.GOLD
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.shadow_color = Color(1.0, 0.84, 0.0, 0.5)
	stylebox.shadow_size = 8
	stylebox.shadow_offset = Vector2(0, 0)
	slot_data.container.add_theme_stylebox_override("panel", stylebox)
	slot_data.container.modulate = Color(1.2, 1.2, 1.0)


func unfocus_slot(index: int):
	if index < 0 or index >= slots.size():
		return
	var slot_data = slots[index]
	slot_data.front.visible = true
	slot_data.back.visible = false
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	stylebox.border_color = Color(0.4, 0.4, 0.5)
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	slot_data.container.add_theme_stylebox_override("panel", stylebox)
	slot_data.container.modulate = Color.WHITE

func update_ui():
	if grid == null or player == null:
		return
	if player.inventory.size() == 0:
		return
	
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()
	slots.clear()
	
	for i in range(player.inventory.size()):
		var weapon_data = player.inventory[i]
		if weapon_data == null:
			continue
		
		var card_container = PanelContainer.new()
		card_container.custom_minimum_size = Vector2(100, 120)
		var default_style = StyleBoxFlat.new()
		default_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		default_style.border_color = Color(0.4, 0.4, 0.5)
		default_style.border_width_left = 2
		default_style.border_width_right = 2
		default_style.border_width_top = 2
		default_style.border_width_bottom = 2
		default_style.corner_radius_top_left = 8
		default_style.corner_radius_top_right = 8
		default_style.corner_radius_bottom_left = 8
		default_style.corner_radius_bottom_right = 8
		card_container.add_theme_stylebox_override("panel", default_style)
		
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_container.add_child(vbox)
		
		# Ön yüz
		var front_side = TextureRect.new()
		front_side.name = "FrontSide"
		if weapon_data.texture:
			front_side.texture = weapon_data.texture
		front_side.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		front_side.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		front_side.custom_minimum_size = Vector2(80, 80)
		vbox.add_child(front_side)
		
		# Arka yüz
		var back_side = VBoxContainer.new()
		back_side.name = "BackSide"
		back_side.visible = false
		back_side.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var name_label = Label.new()
		name_label.text = weapon_data.name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color.GOLD)
		back_side.add_child(name_label)
		
		var spacer1 = Control.new()
		spacer1.custom_minimum_size = Vector2(0, 5)
		back_side.add_child(spacer1)
		
		var damage_label = Label.new()
		damage_label.text = "⚔️ ATK: %d" % weapon_data.damage
		damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		damage_label.add_theme_color_override("font_color", Color.ORANGE_RED)
		back_side.add_child(damage_label)
		
		var speed_label = Label.new()
		speed_label.text = "⚡ SPD: %.1fs" % weapon_data.cooldown
		speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		speed_label.add_theme_color_override("font_color", Color.DEEP_SKY_BLUE)
		back_side.add_child(speed_label)
		
		var element_label = Label.new()
		var element_name = WeaponData.ElementType.keys()[weapon_data.element]
		element_label.text = "🔥 %s" % element_name
		element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		element_label.add_theme_color_override("font_color", get_element_color(weapon_data.element))
		back_side.add_child(element_label)
		
		vbox.add_child(back_side)
		
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(100, 120)
		slot_button.flat = true
		slot_button.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_button.focus_mode = Control.FOCUS_ALL
		card_container.add_child(slot_button)
		
		slots.append({
			"container": card_container,
			"front": front_side,
			"back": back_side,
			"button": slot_button,
			"index": i
		})
		
		slot_button.mouse_entered.connect(func():
			unfocus_slot(current_focus_index)
			current_focus_index = i
			focus_slot(i)
		)
		slot_button.mouse_exited.connect(func():
			unfocus_slot(i)
		)
		
		slot_button.pressed.connect(func():
			play_select_sound()
			on_slot_clicked(i)
		)
		
		grid.add_child(card_container)

func get_element_color(element: int) -> Color:
	match element:
		WeaponData.ElementType.FIRE: return Color.ORANGE_RED
		WeaponData.ElementType.ICE: return Color.CYAN
		WeaponData.ElementType.LIGHTNING: return Color.YELLOW
		_: return Color.WHITE

func on_slot_clicked(index):
	if player:
		player.equip_weapon(index)
		toggle_inventory()

func play_navigate_sound():
	if navigate_sound:
		navigate_sound.play()

func play_select_sound():
	if select_sound:
		select_sound.play()
