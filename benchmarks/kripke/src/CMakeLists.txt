include_directories(.)
#include_directories("$ENV{HOME}/geopm/install-dev/include")

add_subdirectory(Kripke)

set(KRIPKE_LIBS ${KRIPKE_LIBS} PARENT_SCOPE)
