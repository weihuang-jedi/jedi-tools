#-----------------------------------------------------------------------------

include make_rules

####################################################

OBJS =	module_namelist.o \
	nc_get1Dint.o \
	nc_get1Dvar.o \
	nc_get2Dint.o \
	nc_get2Dvar.o \
	nc_get3Dint.o \
	nc_get3Dvar.o \
	nc_get4Dvar.o \
	nc_get5Dvar.o \
	nc_getGlobalIntAttr.o \
	nc_getGlobalRealAttr.o \
	nc_getGlobalCharAttr.o \
	nc_put_single_int.o \
	nc_put1Dvar.o \
	nc_put1Dint.o \
	nc_put2Dvar.o \
	nc_put2Dint.o \
	nc_put3Dvar.o \
	nc_put3Dint.o \
	nc_put4Dvar.o \
	nc_put5Dvar.o \
	nc_putChar.o \
	nc_putAttr.o \
	nc_putAxisAttr.o \
	nc_putAxisIntAttr.o \
	nc_putIntAttr.o \
	nc_putGlobalIntAttr.o \
	nc_putGlobalRealAttr.o \
	nc_putGlobalCharAttr.o \
	grid_module.o \

####################################################

deflt :	clean_modulde nc4_lib concatefiles

clean_modulde :
	$(RM) latlon_module.f90 latlon_module.mod latlon_module.o grid_module.f90 grid_module.mod grid_module.o

nc4_lib : $(OBJS)
	$(RM) libnc4.a
	$(AR) libnc4.a $(OBJS)
	$(RANLIB) libnc4.a

concatefiles : concatefiles.o
	$(FC) -o concatefiles.exe concatefiles.o $(FFLAGS) $(LOC_LIBS) \
	libnc4.a

clean :
	$(RM) libnc4.a $(OBJS) concatefiles.o \
	*.f90 *.mod *.exe

####################################################

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)

grid_module.o : grid_module.F90

