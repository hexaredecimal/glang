[[core]]
struct raven {}

[[cpp_include("examples/workspace/raven_glue.hpp"), extern, c_abi,
  link_name("Rinit")]]
int raven::init(int backend);

[[extern, c_abi, link_name("Rshutdown")]]
void raven::shutdown();

[[extern, c_abi, link_name("Rwait_frame")]]
int raven::wait_frame(double timeout_seconds);

[[extern, c_abi, link_name("glang_raven_error_set_callback")]]
void raven::error_set_callback((int, int, const char*) -> void callback);

[[extern, c_abi, link_name("Rerror_to_string")]]
const char* raven::error_to_string(int error);

[[extern, c_abi, link_name("Rseverity_to_string")]]
const char* raven::severity_to_string(int severity);

[[extern, c_abi, link_name("glang_raven_action_bind")]]
void raven::action_bind(const char* name,
                        (uint, const char*) -> void callback);

[[extern, c_abi, link_name("Rwindow_create_from_xml_file")]]
uint raven::window_create_from_xml_file(const char* path);

[[extern, c_abi, link_name("Rwidget_find")]]
uint raven::widget_find(uint scope, const char* name);

[[extern, c_abi, link_name("Rwidget_is_valid")]]
int raven::widget_is_valid(uint widget);

[[extern, c_abi, link_name("Rwidget_set_material")]]
void raven::widget_set_material(uint widget, int material);

[[extern, c_abi, link_name("Rtheme_apply")]]
void raven::theme_apply(int theme);

[[extern, c_abi, link_name("Rtheme_set_material")]]
void raven::theme_set_material(int material);

[[extern, c_abi, link_name("Rlabel_set_text")]]
void raven::label_set_text(uint label, const char* text);

[[extern, c_abi, link_name("Rlist_view_add_item")]]
int raven::list_view_add_item(uint list_view, const char* text);

[[extern, c_abi, link_name("Rlist_view_get_item_count")]]
int raven::list_view_get_item_count(uint list_view);

[[extern, c_abi, link_name("Rlist_view_scroll_to_item")]]
void raven::list_view_scroll_to_item(uint list_view, int index);

[[extern, c_abi, link_name("Rcombo_box_get_selected")]]
int raven::combo_box_get_selected(uint combo_box);

[[extern, c_abi, link_name("Rcombo_box_get_item_text")]]
const char* raven::combo_box_get_item_text(uint combo_box, int index);

[[extern, c_abi, link_name("Rcombo_box_set_selected")]]
void raven::combo_box_set_selected(uint combo_box, int index);

[[extern, c_abi, link_name("Rtext_editor_set_text")]]
void raven::text_editor_set_text(uint editor, const char* text);

[[extern, c_abi, link_name("Rtext_editor_create")]]
uint raven::text_editor_create(const char* text);

[[extern, c_abi, link_name("Rtext_editor_set_line_numbers")]]
void raven::text_editor_set_line_numbers(uint editor, int enabled);

[[extern, c_abi, link_name("Rtext_editor_set_language")]]
void raven::text_editor_set_language(uint editor, const char* language);

[[extern, c_abi, link_name("Rlanguage_for_file")]]
const char* raven::language_for_file(const char* path);

[[extern, c_abi, link_name("Rdock_area_add_panel")]]
void raven::dock_area_add_panel(uint area, uint panel, const char* title,
                                int side, uint relative, float size);

[[extern, c_abi, link_name("Rdock_area_show_panel")]]
void raven::dock_area_show_panel(uint area, uint panel);

[[extern, c_abi, link_name("Rdock_area_save_layout")]]
const char* raven::dock_area_save_layout(uint area);

[[extern, c_abi, link_name("Rdock_area_load_layout")]]
int raven::dock_area_load_layout(uint area, const char* layout);

[[extern, c_abi, link_name("glang_raven_dock_area_set_close_callback")]]
void raven::dock_area_set_close_callback(
    uint area, (uint, uint) -> int callback);

[[extern, c_abi, link_name("glang_raven_dock_area_set_changed_callback")]]
void raven::dock_area_set_changed_callback(uint area, (uint) -> void callback);

[[extern, c_abi, link_name("Rfile_browser_set_directory")]]
void raven::file_browser_set_directory(uint browser, const char* path);

[[extern, c_abi, link_name("glang_raven_file_browser_set_accepted_callback")]]
void raven::file_browser_set_accepted_callback(
    uint browser, (uint, const char*) -> void callback);

[[extern, c_abi, link_name("Rfile_read")]]
char* raven::file_read(const char* path, size_t* size);

[[extern, c_abi, link_name("Rmemory_free")]]
void raven::memory_free(void* memory);

[[extern, c_abi, link_name("Risland_expand_for")]]
void raven::island_expand_for(uint island, double seconds);
