extends Control

var db : SQLite
var selected_image_path : String = "" # Variable para almacenar la ruta de la imagen seleccionada
@onready var image_file_dialog = $"ImageFileDialog"# Asigna tu nodo FileDialog aquí
@onready var search_object_text_edit: TextEdit = %SearchObject

func _ready():
	#inicializando la base de datos
	db = SQLite.new()
	#creando el archivo de base de datos a la ruta
	db.path = "res://database.db"
	db.open_db()
	
	# Configura el FileDialog
	image_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	image_file_dialog.access = FileDialog.ACCESS_RESOURCES # O FileDialog.ACCESS_USERDATA si quieres guardar fuera de res://
	image_file_dialog.filters = ["*.png, *.jpg, *.jpeg ; Image Files"]
	image_file_dialog.title = "Selecciona una Imagen"
	image_file_dialog.current_path = "res://" # Ruta inicial

	# Conecta la señal 'file_selected' del FileDialog
	image_file_dialog.file_selected.connect(_on_image_file_selected)
	pass

func _on_insert_data_button_down() :
	var current_unix_time = Time.get_unix_time_from_system()
	var formatted_creation_date = Time.get_datetime_string_from_unix_time(current_unix_time)

	var data= {
		"username" : $name.text,
		"email": $email.text,
		"password": $password.text,
		"creation_date": formatted_creation_date
	}
	db.insert_row("users",data)
	print("El usuario " + $name.text + " ha sido registrado correctamente.")
	print("Fecha de registro: " + formatted_creation_date) 
	pass


#creacion de todas las tablas de la base de datos
func _on_create_table_button_down():
# Definición y creación de la tabla 'users'
	var table_users = {
		"id": {"data_type":"int", "primary_key": true,"not_null":true, "auto_increment":true},
		"username": {"data_type": "text","not_null":true},
		"email": {"data_type": "text","not_null":true},
		"password": {"data_type": "text","not_null":true},
		"creation_date": {"data_type": "datetime","not_null":true}
	}
	db.create_table("users", table_users)

	# Definición y creación de la tabla 'spaces'
	var table_space = {
		"id": {"data_type":"int", "primary_key": true,"not_null":true, "auto_increment":true},
		"name": {"data_type": "text","not_null":true},
		"route": {"data_type": "text","not_null":true},
		"favorite": {"data_type": "bool","not_null":true},
		"creation_date": {"data_type": "datetime","not_null":true}, 
	}
	db.create_table("spaces", table_space)
	
	var table_object = {
		"id": {"data_type": "int","primary_key":true,"not_null":true,"auto_increment":true},
		"catalog_id": {"data_type": "int","not_null":true, 
		"foreign_key":{"table": "catalog", 
						"column": "id", "on_delete": "CASCADE", 
						"on_update": "CASCADE"}},
		"route":{"data_type": "text", "not_null":true},
		"height":{"data_type":"float","not_null":true},
		"width":{"data_type":"float","not_null":true},
		"nameObject":{"data_type":"text","not_null":true},
		"image":{"data_type": "blob"}
		
	}
	db.create_table("objects",table_object)
	
	# Definición y creación de la tabla 'catalogos'
	var table_catalog = {
		"id": {"data_type": "int","primary_key":true,"not_null":true,"auto_increment":true},
		"owner": {"data_type": "text", "not_null":true},
		"description":{"data_type": "text","not_null":true}
	}
	db.create_table("catalogs",table_catalog)
	
	#creacion de tablas auxiliares
	
	var table_space_object = {
		"id": {"data_type": "int","primary_key":true,"not_null":true,"auto_increment":true},
		"object_id":{"data_type": "int", "not_null":true, 
		"foreign_key":{"table": "objects", 
					   "column": "id", 
					   "on_delete": "CASCADE", 
					   "on_update": "CASCADE"}},
		"space_id": {"data_type": "int", "not_null": true, 
					 "foreign_key": { "table": "spaces",
									  "column": "id",
									  "on_delete": "CASCADE",
									  "on_update":"CASCADE"}}
	}
	db.create_table("space_objects", table_space_object)
	
	print("Todas las tablas han sido creadas con exitos, tablas: USERS,OBJECTS,SPACES,CATALOGS,USER_SPACES,OBJECT_SPACES")
	pass

func _on_select_data_button_down():
	print(db.select_rows("users","username == '" + $name.text + "'", ["*"]))
	pass # Replace with function body.


func _on_delect_data_button_down() :
	db.delete_rows("users", "username = '" + $name.text + "'")
	print("El usuario: " + $name.text +  " ha sido eliminado")
	pass # Replace with function body.

# Función para abrir el FileDialog cuando el botón sea presionado
func _on_select_image_button_down() -> void:
	image_file_dialog.popup_centered()
	

# Función que se ejecuta cuando el usuario selecciona un archivo en el FileDialog
func _on_image_file_selected(path: String) -> void:
	selected_image_path = path
	print("Ruta de la imagen seleccionada: ", selected_image_path)
	# Opcional: Actualiza un LineEdit para mostrar la ruta al usuario
	$route.text = selected_image_path


func _on_insert_data_object_button_down() -> void:
	if selected_image_path.is_empty():
		print("Error: No se ha seleccionado ninguna imagen.")
		return
	var image:= load(selected_image_path)
	var pba = image.get_image().save_png_to_buffer()
	
	var data= {
		"catalog_id" : int($catalog_id.text),
		"route": selected_image_path, 
		"height": float($height.text), 
		"width": float($width.text),   
		"nameObject": $nameObject.text,
		"image": pba
	}
	db.insert_row("objects",data)
	print("El objeto ha sido registrado correctamente con la imagen: " + selected_image_path)
	# Limpiar la ruta seleccionada después de la inserción
	selected_image_path = ""
	pass


func _on_select_image_button_pressed() -> void:
	image_file_dialog.popup_centered()
	pass # Replace with function body.


func _on_delect_object_button_down() -> void:
	db.delete_rows("objects", "nameObject = '" + $nameObject.text + "'")
	print("El objeto: " + $nameObject.text +  " ha sido eliminado")
	pass # Replace with function body.


func _on_insert_space_data_button_down() -> void:
	var current_unix_time = Time.get_unix_time_from_system()
	var formatted_creation_date = Time.get_datetime_string_from_unix_time(current_unix_time)
	var is_favorite = $Favorite.button_pressed
	var data= {
		"name" : $space_name.text,
		"route": $space_route.text,
		"favorite": is_favorite, #guarda valores binarios
		"creation_date": formatted_creation_date
	}
	db.insert_row("spaces",data)
	print("El proyecto " + $space_name.text + " ha sido registrado correctamente.")
	print("Fecha de registro: " + formatted_creation_date) 
	pass
	pass # Replace with function body.


func _on_search_button_button_down() -> void:
	var search_char = $SearchObject.text
	# Usamos db.select_rows para una lógica más consistente con la segunda función
	var where_clause = "nameObject LIKE '%%" + search_char + "%%'" # Doble % para escapar en el string de Godot
	var columns_to_select = ["nameObject", "height", "width"]

	var results = db.select_rows("objects", where_clause, columns_to_select)

	if results is Array and not results.is_empty():
		print("\n--- Found Objects: ---") # Mensaje inicial similar
		for obj in results:
			if obj is Dictionary and obj.has("nameObject") and obj.has("height") and obj.has("width"):
				var name_obj = obj["nameObject"]
				var height = obj["height"]
				var width = obj["width"]

				print("Name: %s" % name_obj)
				print("Height: %.2f" % height)
				print("Width: %.2f" % width)
				print("---------------------------") # Separador similar
			else:
				print("WARNING: Unexpected object format in results: ", obj)
				print("---------------------------")
	else:
		print("\n--- No objects found containing '" + search_char + "'. ---") # Mensaje de no encontrados similar

	print("--- End of Object Search ---") # Mensaje final similar

pass


func _on_show_favs_spaces_button_down() -> void:
	var where_clause = "favorite = '1'" 
	var columns_to_select = ["name", "route", "creation_date"]
	var results = db.select_rows("spaces", where_clause, columns_to_select)

	if results is Array and not results.is_empty():
		print("\n--- Favorite Spaces Found: ---")
		for space_data in results:
			if space_data is Dictionary and \
			   space_data.has("name") and \
			   space_data.has("route") and \
			   space_data.has("creation_date"):

				var space_name = space_data["name"]
				var space_route = space_data["route"]
				var space_creation_date = space_data["creation_date"]

				print("Name: %s" % space_name)
				print("Route: %s" % space_route)
				print("Creation Date: %s" % space_creation_date)
				print("---------------------------") 
			else:
				print("WARNING: Unexpected format or missing keys for a space entry: ", space_data)
				print("---------------------------")
	else:
		print("\n--- No Favorite Spaces Found ---")

	print("--- End of Favorite Spaces Search ---")
pass

func _on_delect_spaces_button_down() -> void:
	db.delete_rows("spaces", "name = '" + $space_name.text + "'")
	print("El espacio: " + $space_name.text +  " ha sido eliminado")
	pass # Replace with function body.

func _on_insert_catalog_button_down() -> void:
		var data= {
		"owner" : $catalog_owner.text,
		"description": $catalog_description.text,
	}
		db.insert_row("catalogs",data)
		print("Se ha agregado la categoria " + $catalog_description.text + " al catalogo.")

pass 

func _on_insert_catalog_2_button_down() -> void:
	db.delete_rows("catalogs", "description = '" + $catalog_description.text + "'")
	print("La categoria: " + $catalog_description.text +  " ha sido eliminado")
	pass # Replace with function body.


func _on_update_user_button_down() -> void:

	var user_to_find = $name.text # Assuming this is the username to identify the user

	# Construct the SET clause for updating the username
	var set_name = "username = '" + $name.text + "'"
	db.update_rows("users", set_name, "username = '" + user_to_find +"'")

	# Construct the SET clause for updating the email
	var set_email = "email = '" + $email.text + "'"
	db.update_rows("users", set_email, "username = '" + user_to_find +"'")

	# Construct the SET clause for updating the password
	var set_password = "password = '" + $password.text + "'"
	db.update_rows("users", set_password, "username = '" + user_to_find +"'")

	print("Update operations initiated for user: " + user_to_find)
	pass # Replace with function body.
