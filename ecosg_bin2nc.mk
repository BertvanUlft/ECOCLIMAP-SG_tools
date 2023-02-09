# -------------------------------------------
#
# Makefile for programs to convert binary files to netcdf
#
# -------------------------------------------

# --- include -------------------------------

include config.ECMWF.atos

# --- names -----------------------------

PROG = ecosg_bin2nc

# --- flags -----------------------------

FFLAGS += $(NETCDF4_INCLUDE)
LFLAGS += $(NETCDF4_LIB)

# --- rules -----------------------------

.F90.o: 
	$(FC) -c $(FFLAGS) $<

.SUFFIXES: .F90

# --- objects -----------------------------

# the object files
OBJS = \
		$(PROG).o

# --- targets -----------------------------

all: build clean

build: $(OBJS)
	@ echo "linking $(OBJS)"
	$(FC) $(LFLAGS) -o $(PROG) \
	$(OBJS) $(LIBS)
	mv $(PROG) $(BIN)/$(PROG).x
	@ echo "done building $(PROG)"

# clean
clean:
	- rm -f $(PROG) $(OBJS) *.mod core
	@ echo "done cleaning"
