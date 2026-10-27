/*
 * rime_keys: type key sequences through librime's C API and print what the
 * schema shows. A test tool for DaoHui's CI (package/smoke_daohui_rime keys):
 * it loads the app's own librime.1.dylib, so librime also loads the app's
 * rime-plugins and the schema's Lua scripts run as on a Mac with DaoHui.
 *
 * usage: rime_keys <shared data dir> <user data dir> <log dir> <schema id>
 *                  <key sequence>...
 * Each key sequence (librime syntax, e.g. "su3cl3" or "{Escape}") is typed
 * into the same session; after each one the commit (if any), the preedit
 * and the candidates are printed, one per line, prefixed by the sequence.
 *
 * Build: clang -o rime_keys tools/rime_keys.c -I librime/src \
 *          -L <DaoHui.app>/Contents/Frameworks -lrime.1 \
 *          -Wl,-rpath,<DaoHui.app>/Contents/Frameworks
 */
#include <stdio.h>

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
    if (!rime->simulate_key_sequence(session, keys)) {
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
      printf("%s\tpreedit\t%s\n", keys, str(context.composition.preedit));
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
