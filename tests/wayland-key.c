// Opt-in live input probe, not part of automatic tests.
// cc tests/wayland-key.c -o /tmp/archblato-key $(pkg-config --cflags --libs wayland-client xkbcommon)
#define _GNU_SOURCE
#include <wayland-client.h>
#include <xkbcommon/xkbcommon.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static struct wl_display *display;
static struct wl_seat *seat;
static struct wl_proxy *manager;
static const struct wl_interface keyboard_interface;
static const struct wl_interface *create_types[] = {&wl_seat_interface, &keyboard_interface};
static const struct wl_message keyboard_methods[] = {
    {"keymap", "uhu", NULL}, {"key", "uuu", NULL},
    {"modifiers", "uuuu", NULL}, {"destroy", "", NULL}
};
static const struct wl_interface keyboard_interface = {"zwp_virtual_keyboard_v1", 1, 4, keyboard_methods, 0, NULL};
static const struct wl_message manager_methods[] = {{"create_virtual_keyboard", "on", create_types}};
static const struct wl_interface manager_interface = {"zwp_virtual_keyboard_manager_v1", 1, 1, manager_methods, 0, NULL};
static void global(void *data, struct wl_registry *registry, uint32_t name, const char *interface, uint32_t version) {
    (void)data; (void)version;
    if (!strcmp(interface, "wl_seat")) seat = wl_registry_bind(registry, name, &wl_seat_interface, 1);
    if (!strcmp(interface, manager_interface.name)) manager = wl_registry_bind(registry, name, &manager_interface, 1);
}
static void removed(void *data, struct wl_registry *registry, uint32_t name) {(void)data;(void)registry;(void)name;}
static const struct wl_registry_listener listener = {global, removed};
static uint32_t now(void) {struct timespec t;clock_gettime(CLOCK_MONOTONIC,&t);return (uint32_t)(t.tv_sec*1000+t.tv_nsec/1000000);}
static void key(struct wl_proxy *keyboard, uint32_t code, uint32_t state) {
    wl_proxy_marshal(keyboard,1,now(),code,state); wl_display_roundtrip(display);
}
int main(int argc, char **argv) {
    uint32_t code=0, modifierCode=0;
    const char *modifierName=NULL;
    if (argc!=2) return 2;
    if (!strcmp(argv[1],"super")) {code=125;modifierName=XKB_MOD_NAME_LOGO;}
    else if (!strcmp(argv[1],"escape")) code=1;
    else if (!strcmp(argv[1],"tab")) code=15;
    else if (!strcmp(argv[1],"right")) code=106;
    else if (!strcmp(argv[1],"left")) code=105;
    else if (!strcmp(argv[1],"ctrl-tab")) {code=15;modifierCode=29;modifierName=XKB_MOD_NAME_CTRL;}
    else return 2; // No arbitrary typing or destructive shortcuts.
    display=wl_display_connect(NULL);
    if (!display) return 3;
    struct wl_registry *registry=wl_display_get_registry(display);
    wl_registry_add_listener(registry,&listener,NULL);wl_display_roundtrip(display);
    if (!seat || !manager) {fprintf(stderr,"virtual keyboard unavailable\n");return 4;}
    struct wl_proxy *keyboard=wl_proxy_marshal_constructor(manager,0,&keyboard_interface,seat,NULL);
    struct xkb_context *context=xkb_context_new(XKB_CONTEXT_NO_FLAGS);
    struct xkb_rule_names names={.layout="us"};
    struct xkb_keymap *map=xkb_keymap_new_from_names(context,&names,XKB_KEYMAP_COMPILE_NO_FLAGS);
    char *text=xkb_keymap_get_as_string(map,XKB_KEYMAP_FORMAT_TEXT_V1);
    size_t size=strlen(text)+1;
    int fd=memfd_create("archblato-test-keymap",MFD_CLOEXEC);
    if(fd<0 || write(fd,text,size)!=(ssize_t)size) return 5;
    wl_proxy_marshal(keyboard,0,WL_KEYBOARD_KEYMAP_FORMAT_XKB_V1,fd,(uint32_t)size);
    wl_display_roundtrip(display);close(fd);free(text);
    uint32_t mods=modifierName ? 1u<<xkb_keymap_mod_get_index(map,modifierName) : 0;
    if(modifierCode) key(keyboard,modifierCode,1);
    if(code==125) key(keyboard,code,1);
    if(mods) {wl_proxy_marshal(keyboard,2,mods,0u,0u,0u);wl_display_roundtrip(display);}
    if(code!=125) key(keyboard,code,1);
    usleep(50000);
    key(keyboard,code,0);
    if(modifierCode) key(keyboard,modifierCode,0);
    wl_proxy_marshal(keyboard,2,0u,0u,0u,0u);
    wl_display_roundtrip(display);
    wl_proxy_marshal(keyboard,3);wl_display_roundtrip(display);wl_proxy_destroy(keyboard);
    xkb_keymap_unref(map);xkb_context_unref(context);wl_display_disconnect(display);
    return 0;
}
