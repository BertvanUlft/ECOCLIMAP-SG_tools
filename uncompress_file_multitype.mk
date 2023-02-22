# -------------------------------------------
#
# Makefile for program to uncompress ECOCLIMAP-SG binary files
#
# -------------------------------------------

# --- include -------------------------------

include config.ECMWF.atos

# --- names -----------------------------

PROG = uncompress_file_multitype

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
		header_mod.o \
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
