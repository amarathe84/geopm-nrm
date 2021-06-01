include ../InstallPath

CC=mpicc
CPP=mpicxx
all: omp_test.c
	${CPP} -c -o main.geo.omp.o omp_test.c -D_GEOPM_ -I$(GEO_INSTALL_PATH)/include -qopenmp
	${CPP} -o main.geo.omp main.geo.omp.o -D_GEOPM_ -I$(GEO_INSTALL_PATH)/include \
				-L$(GEO_INSTALL_PATH)/lib \
				-L$(GEO_INSTALL_PATH)/lib/geopm/openmp/lib/ \
	            -Xlinker -rpath $(GEO_INSTALL_PATH)/lib \
				-Xlinker -rpath $(GEO_INSTALL_PATH)/lib/geopm/openmp/lib/ \
				-lgeopm -liomp5
	${CPP} -o main.omp omp_test.c -qopenmp
clean:
	/bin/rm -f main.geo.omp
