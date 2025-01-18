extends Node

func idle_status():
	# after 5 min on the menu switch to "listening to music"
	var activity = Discord.Activity.new()
	activity.set_type(Discord.ActivityType.Playing)
	activity.set_details("Main Menu")
	activity.set_state("Listening to music")

	var assets = activity.get_assets()
	assets.set_large_image("icon-bg")
	
	Discord.activity_manager.update_activity(activity)

func _ready():
	print("CEF version: " + $CEF.get_full_version()) 
	if !$CEF.initialize({"locale":"en-US"}):
		print($CEF.get_error())
		return;
		
	current_browser = create_browser(HOME_PAGE)
	
	get_tree().paused = false
	if Rhythia.arcw_mode:
		get_tree().change_scene("res://w.tscn")
	if Rhythia.sex_mode:
		get_tree().change_scene("res://sex.tscn")
	if Rhythia.memory_lane:
		get_tree().change_scene("res://dya.tscn")
	
	# fix audio pitchshifts
	if AudioServer.get_bus_effect_count(AudioServer.get_bus_index("Music")) > 0:
		AudioServer.remove_bus_effect(AudioServer.get_bus_index("Music"),0)
	
	$BlackFade.visible = true
	$BlackFade.color = Color(0,0,0,black_fade)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if ProjectSettings.get_setting("application/config/discord_rpc"):
		var activity = Discord.Activity.new()
		activity.set_type(Discord.ActivityType.Playing)
		activity.set_details("Main Menu")	
		activity.set_state("Selecting a song")

		var assets = activity.get_assets()
		assets.set_large_image("icon-bg")

		Discord.activity_manager.update_activity(activity)
		
		get_tree().create_timer(300).connect("timeout",self,"idle_status")

var black_fade_target:bool = false
var black_fade:float = 1

func _process(delta):
	if Input.is_action_just_pressed("ui_end") and Input.is_key_pressed(KEY_SHIFT):
		get_tree().change_scene("res://scenes/loaders/menuload.tscn")

	if black_fade_target && black_fade != 1:
		black_fade = min(black_fade + (delta/0.3),1)
		$BlackFade.color = Color(0,0,0,black_fade)
	elif !black_fade_target && black_fade != 0:
		black_fade = max(black_fade - (delta/0.5),0)
		$BlackFade.color = Color(0,0,0,black_fade)
	$BlackFade.visible = (black_fade != 0)
	
	
const HOME_PAGE = "https://ax.rhythia.com"

onready var current_browser = null
onready var mouse_pressed : bool = false

func create_browser(url):
	var S = $TextureRect.get_size()
	var browser = $CEF.create_browser(url, "browser_name", S.x, S.y, {"javascript":true,"frame_rate":30,"webgl":true})
	if browser == null:
		return null
	print("Created", url)
	browser.connect("page_loaded", self, "_on_page_loaded")
	$TextureRect.texture = browser.get_texture()
	$TextureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return browser

func _on_page_loaded(node):
	var url = node.get_url()
	print("Browser : " + url)

func _on_TextureRect_gui_input(event):
	if current_browser == null:
		return
		
	# Get texture data for transparency check
	var texture = $TextureRect.texture
	if texture == null:
		return
		
	var image = Image.new()
	image.copy_from($TextureRect.texture)
	image.lock()
	
	# Use event position 
	var mouse_pos = event.position
	
	# Check if position is within bounds
	if mouse_pos.x < 0 or mouse_pos.y < 0 or mouse_pos.x >= texture.get_width() or mouse_pos.y >= texture.get_height():
		image.unlock()
		return
		
	# Get alpha value at mouse position
	var alpha = image.get_pixel(mouse_pos.x, mouse_pos.y).a
	image.unlock()
	
	# Only process events if pixel is transparent (alpha < threshold)
	if alpha < 0.1:  # Adjust threshold as needed
		return
	print(alpha)
	if current_browser == null:
		return
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			current_browser.on_mouse_wheel_vertical(2)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			current_browser.on_mouse_wheel_vertical(-2)
		elif event.button_index == BUTTON_LEFT:
			mouse_pressed = event.pressed
			if event.pressed == true:
				current_browser.on_mouse_left_down()
			else:
				current_browser.on_mouse_left_up()
		elif event.button_index == BUTTON_RIGHT:
			mouse_pressed = event.pressed
			if event.pressed == true:
				current_browser.on_mouse_right_down()
			else:
				current_browser.on_mouse_right_up()
		else:
			mouse_pressed = event.pressed
			if event.pressed == true:
				current_browser.on_mouse_middle_down()
			else:
				current_browser.on_mouse_middle_up()
	elif event is InputEventMouseMotion:
		if mouse_pressed == true :
			current_browser.on_mouse_left_down()
		current_browser.on_mouse_moved(event.position.x, event.position.y)
	pass

# ==============================================================================
# Make the CEF browser reacts from keyboard events.
# ==============================================================================
func _input(event):
	if current_browser == null:
		return
	if not event is InputEventKey:
		return
	if event is InputEventKey:
		if event.unicode != 0:
			current_browser.on_key_pressed(event.unicode, event.pressed, event.shift, event.alt, event.control)
		else:
			current_browser.on_key_pressed(event.scancode, event.pressed, event.shift, event.alt, event.control)
	pass
	
func _on_TextureRect_resized():
	if current_browser == null:
		return
	current_browser.resize($TextureRect.get_size().x, $TextureRect.get_size().y)
	pass
