extends CanvasLayer

var player = null
@onready var grid = %GridContainer
@onready var stats_label = %RichTextLabel 

var current_focus_index = 0
var slots = []


# Ses efektleri (AudioStreamPlayer node'ları sahneye eklemen gerekecek)
@onready var navigate_sound = $SelectSound   # Kaydırma sesi
@onready var select_sound = %NavigateSound 
 

func _ready():
	visible = false
	
	# GridContainer sütun sayısını ayarla (4 sütunlu grid)
	if grid:
		grid.columns = 4

func set_player_reference(p):
	player = p

func _input(event):
	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
	
	# Envanter açıkken gamepad kontrolü
	if visible:
		if event.is_action_pressed("ui_right"):
			navigate_slots(1)
			play_navigate_sound()
		elif event.is_action_pressed("ui_left"):
			navigate_slots(-1)
			play_navigate_sound()
		elif event.is_action_pressed("ui_down"):
			navigate_slots(grid.columns)
			play_navigate_sound()
		elif event.is_action_pressed("ui_up"):
			navigate_slots(-grid.columns)
			play_navigate_sound()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
			# Enter veya gamepad A/X butonu ile seçim
			if slots.size() > 0 and current_focus_index < slots.size():
				play_select_sound()
				on_slot_clicked(current_focus_index)

func toggle_inventory():
	visible = !visible
	get_tree().paused = visible
	
	if visible:
		update_ui()
		# Envanter açıldığında ilk slotu seç
		current_focus_index = 0
		if slots.size() > 0:
			focus_slot(current_focus_index)
	else:
		stats_label.clear()
		slots.clear()

func navigate_slots(direction: int):
	if slots.size() == 0:
		return
	
	# Mevcut focus'u kaldır
	unfocus_slot(current_focus_index)
	
	# Yeni index hesapla
	current_focus_index += direction
	
	# Sınırları kontrol et (wrap around)
	if current_focus_index < 0:
		current_focus_index = slots.size() - 1
	elif current_focus_index >= slots.size():
		current_focus_index = 0
	
	# Yeni slotu seç
	focus_slot(current_focus_index)

func focus_slot(index: int):
	if index < 0 or index >= slots.size():
		return
	
	var slot_data = slots[index]
	var card_container = slot_data.container
	var front_side = slot_data.front
	var back_side = slot_data.back
	
	# Kartı çevir ve vurgula
	front_side.visible = false
	back_side.visible = true
	
	# PARLAK KENARLIK EFEKTİ
	# StyleBox ile kenarlık ekleme
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.25, 0.8)  # Koyu arka plan
	stylebox.border_color = Color.GOLD  # Altın kenarlık
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	
	# Glow efekti için shadow
	stylebox.shadow_color = Color(1.0, 0.84, 0.0, 0.5)  # Altın glow
	stylebox.shadow_size = 8
	stylebox.shadow_offset = Vector2(0, 0)
	
	card_container.add_theme_stylebox_override("panel", stylebox)
	card_container.modulate = Color(1.2, 1.2, 1.0)  # Hafif parlaklık
	
	# Slotun butonunu focus'la (klavye navigasyonu için)
	if slot_data.button:
		slot_data.button.grab_focus()

func unfocus_slot(index: int):
	if index < 0 or index >= slots.size():
		return
	
	var slot_data = slots[index]
	var card_container = slot_data.container
	var front_side = slot_data.front
	var back_side = slot_data.back
	
	# Kartı geri çevir
	front_side.visible = true
	back_side.visible = false
	
	# Normal kenarlık
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
	
	card_container.add_theme_stylebox_override("panel", stylebox)
	card_container.modulate = Color.WHITE

func update_ui():
	if grid == null: return
	
	# Eski slotları temizle
	for child in grid.get_children():
		child.queue_free()
	
	slots.clear()
	
	# Her silah için slot oluştur
	for i in range(player.inventory.size()):
		var weapon_data = player.inventory[i]
		
		# Ana container (Kartın kendisi)
		var card_container = PanelContainer.new()
		card_container.custom_minimum_size = Vector2(100, 120)
		
		# Başlangıç stili
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
		
		# İçerik için VBoxContainer
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_container.add_child(vbox)
		
		# ÖN YÜZ: Silah resmi
		var front_side = TextureRect.new()
		front_side.name = "FrontSide"
		front_side.texture = weapon_data.texture
		front_side.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		front_side.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		front_side.custom_minimum_size = Vector2(80, 80)
		vbox.add_child(front_side)
		
		# ARKA YÜZ: İstatistikler (başta gizli)
		var back_side = VBoxContainer.new()
		back_side.name = "BackSide"
		back_side.visible = false
		back_side.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Stat labelları - RENKLERLE
		var name_label = Label.new()
		name_label.text = weapon_data.name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color.GOLD)
		back_side.add_child(name_label)
		
		# Boşluk
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
		# Element'e göre renk
		var element_color = get_element_color(weapon_data.element)
		element_label.text = "🔥 %s" % element_name
		element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		element_label.add_theme_color_override("font_color", element_color)
		back_side.add_child(element_label)
		
		vbox.add_child(back_side)
		
		# Tıklanabilir alan için Button
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(100, 120)
		slot_button.flat = true
		slot_button.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_button.focus_mode = Control.FOCUS_ALL
		card_container.add_child(slot_button)
		
		# Slot verisini kaydet
		slots.append({
			"container": card_container,
			"front": front_side,
			"back": back_side,
			"button": slot_button,
			"index": i
		})
		
		# Mouse olayları
		slot_button.mouse_entered.connect(func():
			current_focus_index = i
			focus_slot(i)
		)
		
		slot_button.mouse_exited.connect(func():
			unfocus_slot(i)
		)
		
		# Gamepad focus olayları
		slot_button.focus_entered.connect(func():
			current_focus_index = i
			focus_slot(i)
		)
		
		slot_button.focus_exited.connect(func():
			unfocus_slot(i)
		)
		
		# Tıklama olayı
		slot_button.pressed.connect(func():
			play_select_sound()  # ← SES EKLE
			on_slot_clicked(i)
)
		
		# Grid'e ekle
		grid.add_child(card_container)

func get_element_color(element: int) -> Color:
	match element:
		WeaponData.ElementType.FIRE:
			return Color.ORANGE_RED
		WeaponData.ElementType.ICE:
			return Color.CYAN
		WeaponData.ElementType.LIGHTNING:
			return Color.YELLOW
		_:
			return Color.WHITE

func on_slot_clicked(index):
	if player:
		player.equip_weapon(index)
		toggle_inventory()

# SES FONKSİYONLARI
func play_navigate_sound():
	if navigate_sound:
		navigate_sound.play()


func play_select_sound():
	if select_sound:
		select_sound.play()



