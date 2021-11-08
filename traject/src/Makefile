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
	module_model.o \
	module_trajectory.o \
	output_trajectory.o

####################################################

deflt :	clean_modulde nc4_lib trajectory

clean_modulde :
	$(RM) module_trajectory.f90 module_trajectory.mod module_trajectory.o module_model.f90 module_model.mod module_model.o

nc4_lib : $(OBJS)
	$(RM) libnc4.a
	$(AR) libnc4.a $(OBJS)
	$(RANLIB) libnc4.a

trajectory : trajectory.o
	$(FC) -o trajectory.exe trajectory.o $(FFLAGS) $(LOC_LIBS) \
	libnc4.a

clean :
	$(RM) libnc4.a $(OBJS) $(TEST_OBJS) trajectory.o \
	*.f90 *.mod *.exe

####################################################

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)

#trajectory.o : module_model.o

#module_model.o : module_model.F90

#module_trajectory.o : module_trajectory.F90

output_trajectory.o : module_trajectory.o

