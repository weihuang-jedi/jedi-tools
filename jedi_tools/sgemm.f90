! Fortran source code is found in dgemm_example.f

      PROGRAM   MAIN

      IMPLICIT NONE

      REAL ALPHA, BETA
      INTEGER   M, P, N, I, J
!     PARAMETER (M=2000, P=200, N=1000)
!     PARAMETER (M=16000, P=8000, N=8000)
      PARAMETER (M=500, P=5000, N=500)
      REAL A(M,P), B(P,N), C(M,N)

      real :: start, finish

      REAL :: rate 
      INTEGER :: c1,c2,cr,cm
    
!     First initialize the system_clock
      CALL system_clock(count_rate=cr)
      CALL system_clock(count_max=cm)
      rate = REAL(cr)

      PRINT *, "This example computes real matrix C=alpha*A*B+beta*C"
      PRINT *, "using Intel® MKL function dgemm, where A, B, and C"
      PRINT *, "are matrices and alpha and beta are double precision "
      PRINT *, "scalars"
      PRINT *, ""

      PRINT *, "Initializing data for matrix multiplication C=A*B for "
      PRINT 10, " matrix A(",M," x",P, ") and matrix B(", P," x", N, ")"
10    FORMAT(a,I5,a,I5,a,I5,a,I5,a)
      PRINT *, ""
      ALPHA = 1.0 
      BETA = 0.0

      PRINT *, "Intializing matrix data"
      PRINT *, ""
      DO I = 1, M
        DO J = 1, P
          A(I,J) = (I-1) * P + J
        END DO
      END DO

      DO I = 1, P
        DO J = 1, N
          B(I,J) = -((I-1) * N + J)
        END DO
      END DO

      DO I = 1, M
        DO J = 1, N
          C(I,J) = 0.0
        END DO
      END DO

      PRINT *, "Computing matrix product using Intel® MKL DGEMM "
      PRINT *, "subroutine"
      call cpu_time(start)
      CALL SYSTEM_CLOCK(c1)
      DO J = 1, 1000
        CALL SGEMM('N','N',M,N,P,ALPHA,A,M,B,P,BETA,C,M)
      END DO
      CALL SYSTEM_CLOCK(c2)
      WRITE(*,*) "system_clock : ",(c2 - c1)/rate
      call cpu_time(finish)
      print '("Time = ",f6.3," seconds.")',finish-start
      PRINT *, "Computations completed."
      PRINT *, ""

      PRINT *, "Top left corner of matrix A:"
      PRINT 20, ((A(I,J), J = 1,MIN(P,6)), I = 1,MIN(M,6))
      PRINT *, ""

      PRINT *, "Top left corner of matrix B:"
      PRINT 20, ((B(I,J),J = 1,MIN(N,6)), I = 1,MIN(P,6))
      PRINT *, ""

 20   FORMAT(6(F12.0,1x))

      PRINT *, "Top left corner of matrix C:"
      PRINT 30, ((C(I,J), J = 1,MIN(N,6)), I = 1,MIN(M,6))
      PRINT *, ""

 30   FORMAT(6(ES12.4,1x))

      PRINT *, "Example completed."
      STOP 

      END

