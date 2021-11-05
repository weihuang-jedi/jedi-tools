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
	module_io.o \
	latlon_module.o \
	output_latlongrid.o \
	interp_vars.o

####################################################

deflt :	clean_modulde nc4_lib fv3interp2latlon

clean_modulde :
	$(RM) latlon_module.f90 latlon_module.mod latlon_module.o module_io.f90 module_io.mod module_io.o

nc4_lib : $(OBJS)
	$(RM) libnc4.a
	$(AR) libnc4.a $(OBJS)
	$(RANLIB) libnc4.a

fv3interp2latlon : fv3interp2latlon.o
	$(FC) -o fv3interp2latlon.exe fv3interp2latlon.o $(FFLAGS) $(LOC_LIBS) \
	libnc4.a

clean :
	$(RM) libnc4.a $(OBJS) $(TEST_OBJS) \
	*.f90 *.mod *.exe

####################################################

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)

#fv3interp2latlon.o : module_io.o

module_io.o : module_io.F90

latlon_module.o : latlon_module.F90

