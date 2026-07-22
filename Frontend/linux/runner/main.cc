#include "campusscorelication.h"

int main(int argc, char **argv) {
  g_autoptr(MyApplication) app = campusscorelication_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
