#include "my_application.h"

#include <cstring>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  // A start at sign-in lives in the tray until the person opens the window.
  gboolean start_hidden;
  // Forwards deep links received while running to the Dart side (audit H8).
  FlMethodChannel* deep_link_channel;
  // Link that arrived before Dart installed its link handler. Dart pulls it
  // with getPendingLink once ready; invoking earlier would drop it because
  // no handler exists yet on the Dart side.
  char* pending_link;
  // Set by Dart's getPendingLink call. Only then may links be invoked
  // directly instead of queued.
  gboolean dart_link_ready;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Channel name the Dart side listens on for links forwarded while running.
static const char kDeepLinkChannel[] = "sora.linux/deep_link";

// Sends a link to Dart; queues it until Dart signals readiness, so a link
// arriving while the Flutter engine is still starting is never lost.
static void my_application_forward_link(MyApplication* self, const char* link) {
  if (link == nullptr || *link == '\0') {
    return;
  }
  if (self->dart_link_ready && self->deep_link_channel != nullptr) {
    g_autoptr(FlValue) value = fl_value_new_string(link);
    fl_method_channel_invoke_method(self->deep_link_channel, "onDeepLink",
                                    value, nullptr, nullptr, nullptr);
  } else {
    g_free(self->pending_link);
    self->pending_link = g_strdup(link);
  }
}

// Dart calls getPendingLink after installing its onDeepLink handler. Marks
// Dart ready so later links are invoked directly, and returns the link
// queued while Dart was starting, if any.
static void deep_link_method_call_handler(FlMethodChannel* channel,
                                           FlMethodCall* method_call,
                                           gpointer user_data) {
  (void)channel;
  MyApplication* self = MY_APPLICATION(user_data);
  if (g_strcmp0(fl_method_call_get_name(method_call), "getPendingLink") == 0) {
    self->dart_link_ready = TRUE;
    g_autoptr(FlValue) result = self->pending_link != nullptr
        ? fl_value_new_string(self->pending_link)
        : fl_value_new_null();
    g_clear_pointer(&self->pending_link, g_free);
    g_autoptr(GError) error = nullptr;
    if (!fl_method_call_respond_success(method_call, result, &error)) {
      g_warning("Failed to respond to getPendingLink: %s", error->message);
    }
    return;
  }
  fl_method_call_respond_not_implemented(method_call, nullptr);
}

// First command-line argument that looks like a link (carries a URI scheme);
// option flags are skipped.
static const char* find_link_arg(char** args) {
  if (args == nullptr) {
    return nullptr;
  }
  for (char** arg = args; *arg != nullptr; ++arg) {
    if ((*arg)[0] == '-') {
      continue;
    }
    if (strstr(*arg, "://") != nullptr) {
      return *arg;
    }
  }
  return nullptr;
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  if (!self->start_hidden) {
    gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  // One window per session: starting Sora again, from the menu, the
  // terminal or a link, brings the window forward, hidden in the tray or not,
  // instead of opening another.
  GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
  if (windows != nullptr) {
    gtk_window_present(GTK_WINDOW(windows->data));
    return;
  }
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // GNOME draws no window controls of its own, so there a header bar carries
  // them. Every other desktop decorates the window itself or, tiled, needs no
  // decoration, and a header bar there is only a grey strip across the app.
  const gchar* desktop = g_getenv("XDG_CURRENT_DESKTOP");
  gboolean use_header_bar = desktop != nullptr && strstr(desktop, "GNOME") != nullptr;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    use_header_bar = g_strcmp0(wm_name, "GNOME Shell") == 0;
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  }
  gtk_window_set_title(window, "Sora");

  // Start with enough room for the server and connection panes.
  gtk_window_set_default_size(window, 1120, 760);
  GdkGeometry limits = {};
  limits.min_width = 360;
  limits.min_height = 560;
  gtk_window_set_geometry_hints(window, nullptr, &limits, GDK_HINT_MIN_SIZE);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // The app_links plugin delivers command-line links from secondary
  // instances through its own channel; this second channel covers the
  // GApplication::open path, which that plugin ignores, and links arriving
  // before Dart is ready. Dart pulls the queued link with getPendingLink
  // once its handler is installed, so nothing is invoked into the void.
  if (self->deep_link_channel == nullptr) {
    g_autoptr(FlPluginRegistrar) registrar =
        fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(view),
                                                    "SoraDeepLink");
    FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    self->deep_link_channel = fl_method_channel_new(
        messenger, kDeepLinkChannel, FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(self->deep_link_channel,
                                              deep_link_method_call_handler,
                                              self, nullptr);
  }

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);
  self->start_hidden = g_strv_contains(*arguments + 1, "--hidden");

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  // The command line goes on to the first instance, where it carries a link
  // opened while Sora runs. Only the primary instance builds a window; a
  // secondary one only forwards its command line and exits.
  if (!g_application_get_is_remote(application)) {
    g_application_activate(application);
  }
  *exit_status = 0;

  return FALSE;
}

// Implements GApplication::command_line.
//
// Invoked for a secondary instance's command line forwarded over D-Bus, and
// once locally for the primary instance's own command line: g_application_run
// emits it after local_command_line returns FALSE (cold start with a link).
// The app_links plugin sees the remote signal through its own hook; the Dart
// side dedups the two deliveries, so a link is never lost and never opens
// twice. A link arriving before Dart is ready stays queued in pending_link
// until Dart pulls it with getPendingLink.
static int my_application_command_line(GApplication* application,
                                       GApplicationCommandLine* command_line) {
  MyApplication* self = MY_APPLICATION(application);
  gint argc = 0;
  g_auto(GStrv) argv =
      g_application_command_line_get_arguments(command_line, &argc);
  const char* link = find_link_arg(argv);
  if (link != nullptr) {
    my_application_forward_link(self, link);
  }
  // Bring the window forward for links opened while Sora runs (remote
  // command lines from a secondary instance). The primary instance already
  // activated in local_command_line; presenting here as well would also
  // break --hidden login starts.
  if (g_application_command_line_get_is_remote(command_line)) {
    my_application_activate(application);
  }
  return 0;
}

// Implements GApplication::open. The app_links plugin ignores this path.
static void my_application_open(GApplication* application, GFile** files,
                                gint n_files, const gchar* hint) {
  MyApplication* self = MY_APPLICATION(application);
  (void)hint;
  for (gint i = 0; i < n_files; ++i) {
    g_autofree char* scheme = g_file_get_uri_scheme(files[i]);
    if (g_strcmp0(scheme, "file") == 0) {
      continue;
    }
    g_autofree char* uri = g_file_get_uri(files[i]);
    my_application_forward_link(self, uri);
  }
  my_application_activate(application);
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_pointer(&self->deep_link_channel, g_object_unref);
  g_clear_pointer(&self->pending_link, g_free);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->command_line = my_application_command_line;
  G_APPLICATION_CLASS(klass)->open = my_application_open;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_HANDLES_COMMAND_LINE |
                                         G_APPLICATION_HANDLES_OPEN,
                                     nullptr));
}
