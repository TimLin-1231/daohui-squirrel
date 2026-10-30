/*
 * rime_keys: type key sequences through librime's C API and print what the
 * schema shows. A test tool for DaoHui's CI (package/smoke_daohui_rime keys):
 * it loads the app's own librime.1.dylib, so librime also loads the app's
 * rime-plugins and the schema's Lua scripts run as on a Mac with DaoHui.
 *
 * usage: rime_keys <shared data dir> <user data dir> <log dir> <schema id>
 *                  <key sequence>...
 * Each key sequence (librime syntax, e.g. "su3cl3" or "{Escape}") is typed
 * into the same session; after each one the commit (if any), the input, the
 * preedit, the inline preview and the candidates are printed, one per line,
 * prefixed by the sequence.
 *
 * Two pseudo sequences play DaoHui's front end for Ctrl+R (lua/asus_fix.lua,
 * sources/DaoHuiAI.swift):
 *   @opt:<name>=0|1   sets an option (e.g. @opt:_asus_fix=1)
 *   @answer:<text>    takes the request in asus_fix_request, answers <text>
 *                     through asus_fix_result and presses F23
 *
 * Build: clang -o rime_keys tools/rime_keys.c -I librime/src \
 *          -L <DaoHui.app>/Contents/Frameworks -lrime.1 \
 *          -Wl,-rpath,<DaoHui.app>/Contents/Frameworks
 */
#include <stdio.h>
#include <string.h>

#include <rime_api.h>

static const char* str(const char* s) { return s ? s : ""; }

int main(int argc, char* argv[]) {
  if (argc < 6) {
    fprintf(stderr,
            "usage: rime_keys <shared dir> <user dir> <log dir> <schema> "
            "<keys>...\n");
    return 2;
  }
  RimeApi* rime = rime_get_api();
  RIME_STRUCT(RimeTraits, traits);
  traits.shared_data_dir = argv[1];
  traits.user_data_dir = argv[2];
  traits.log_dir = argv[3];
  traits.app_name = "rime.daohui-test";
  traits.distribution_name = "DaoHui test";
  traits.distribution_code_name = "DaoHuiTest";
  traits.distribution_version = "0";
  rime->setup(&traits);
  rime->initialize(NULL);
  if (rime->start_maintenance(1))
    rime->join_maintenance_thread();

  RimeSessionId session = rime->create_session();
  if (!session) {
    fprintf(stderr, "rime_keys: cannot create a session\n");
    rime->finalize();
    return 1;
  }
  if (!rime->select_schema(session, argv[4])) {
    fprintf(stderr, "rime_keys: cannot select schema %s\n", argv[4]);
    rime->finalize();
    return 1;
  }
  int status = 0;
  for (int i = 5; i < argc; ++i) {
    const char* keys = argv[i];
    if (strncmp(keys, "@opt:", 5) == 0 && strchr(keys, '=')) {
      char name[256];
      size_t n = (size_t)(strchr(keys, '=') - (keys + 5));
      if (n >= sizeof name) n = sizeof name - 1;
      memcpy(name, keys + 5, n);
      name[n] = '\0';
      rime->set_option(session, name, strchr(keys, '=')[1] == '1');
      continue;
    }
    if (strncmp(keys, "@answer:", 8) == 0) {
      static char request[1 << 16];
      char result[8192];
      if (!rime->get_property(session, "asus_fix_request", request, sizeof request) ||
          !strchr(request, '\t')) {
        printf("%s\trequest\t(none)\n", keys);
        status = 1;
        continue;
      }
      *strchr(request, '\t') = '\0'; /* now the id */
      printf("%s\trequest\t%s\n", keys, request);
      snprintf(result, sizeof result, "%s\t%s", request, keys + 8);
      rime->set_property(session, "asus_fix_request", "");
      rime->set_property(session, "asus_fix_result", result);
      rime->process_key(session, 0xFFD4, 0); /* XK_F23 */
    } else if (!rime->simulate_key_sequence(session, keys)) {
      fprintf(stderr, "rime_keys: bad key sequence %s\n", keys);
      status = 1;
      continue;
    }
    RIME_STRUCT(RimeCommit, commit);
    if (rime->get_commit(session, &commit)) {
      printf("%s\tcommit\t%s\n", keys, str(commit.text));
      rime->free_commit(&commit);
    }
    RIME_STRUCT(RimeContext, context);
    if (rime->get_context(session, &context)) {
      printf("%s\tinput\t%s\n", keys, str(rime->get_input(session)));
      printf("%s\tpreedit\t%s\n", keys, str(context.composition.preedit));
      printf("%s\tpreview\t%s\n", keys, str(context.commit_text_preview));
      for (int j = 0; j < context.menu.num_candidates; ++j) {
        printf("%s\t%d\t%s\t%s\n", keys, j + 1,
               str(context.menu.candidates[j].text),
               str(context.menu.candidates[j].comment));
      }
      rime->free_context(&context);
    }
  }
  rime->destroy_session(session);
  rime->finalize();
  return status;
}
