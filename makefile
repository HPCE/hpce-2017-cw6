CPPFLAGS += -I include -I testu01/include
CPPFLAGS += -g -O3

CPPFLAGS += -std=c++11 -pthread

PROBDIST_SRC = $(wildcard testu01/probdist/*.cpp)
TESTU01_SRC = $(filter-out testu01/testu01/scatter.cpp, $(wildcard testu01/testu01/*.cpp))
MYLIB_SRC = $(filter-out testu01/mylib/tcode.cpp, $(wildcard testu01/mylib/*.cpp) )

lib/probdist.a : $(patsubst %.cpp,%.o,$(PROBDIST_SRC))
	mkdir -p lib
	-rm $@
	ar rcs $@ $^
	ranlib $@

lib/mylib.a : $(patsubst %.cpp,%.o,$(MYLIB_SRC))
	mkdir -p lib
	-rm $@
	ar rcs $@ $^
	ranlib $@

lib/testu01.a : $(patsubst %.cpp,%.o,$(TESTU01_SRC))
	mkdir -p lib
	-rm $@
	ar rcs $@ $^
	ranlib $@

TESTU01_LIBS = lib/testu01.a lib/mylib.a lib/probdist.a

DRIVERS := $(patsubst drivers/driver_%.cpp,%,$(wildcard drivers/*.cpp))
WORKLOADS := $(patsubst workloads/workload_%.cpp,%,$(wildcard workloads/*.cpp))

bin/certify_% : drivers/driver_certify.cpp workloads/workload_%.cpp $(TESTU01_LIBS)
	mkdir -p bin
	g++ $(CPPFLAGS) -o $@ $(LDFLAGS) $< workloads/workload_$*.cpp $(LDLIBS) $(TESTU01_LIBS)

bin/stress_% : drivers/driver_stress.cpp workloads/workload_%.cpp $(TESTU01_LIBS)
	mkdir -p bin
	g++ $(CPPFLAGS) -o $@ $(LDFLAGS) $< workloads/workload_$*.cpp $(LDLIBS) $(TESTU01_LIBS)

bin/search_% : drivers/driver_search.cpp workloads/workload_%.cpp $(TESTU01_LIBS)
	mkdir -p bin
	g++ $(CPPFLAGS) -o $@ $(LDFLAGS) $< workloads/workload_$*.cpp $(LDLIBS) $(TESTU01_LIBS)


print_all_drivers:
	echo $(DRIVERS)

print_all_workloads:
	echo $(WORKLOADS)

print_all_driver_workloads :
	echo $(ALL_DRIVER_WORLOADS)


all : bin/stress_std bin/search_std bin/certify_std