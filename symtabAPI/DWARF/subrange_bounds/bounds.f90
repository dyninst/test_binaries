! Fortran array shapes whose bounds live in the array descriptor or in
! dummy arguments, plus constant-bound controls.
module shapes
contains
  subroutine assumed_shape(x)
    real :: x(:)
    x = 1.0
  end subroutine

  subroutine explicit_dyn(y, lo, hi)
    integer :: lo, hi
    real :: y(lo:hi)
    y = 2.0
  end subroutine

  subroutine assumed_size(v)
    real :: v(*)
    v(1) = 3.0
  end subroutine

  subroutine fixed()
    real :: w(3:7)
    real :: u(10)
    w = 4.0
    u = 5.0
    call sink(w, u)
  end subroutine

  subroutine sink(w, u)
    real :: w(*), u(*)
    w(1) = u(1)
  end subroutine
end module

program p
  use shapes
  real, allocatable :: z(:)
  allocate(z(-2:5))
  call assumed_shape(z)
  call explicit_dyn(z, -2, 5)
  call assumed_size(z)
  call fixed()
  print *, z(1)
end program
