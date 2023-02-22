module header_mod
!---------------------------------------------------------------------------------------------------
! Routines to handle headers for the binary files
!---------------------------------------------------------------------------------------------------
! modules
use netcdf

! options
implicit none
public

contains

!---------------------------------------------------------------------------------------------------

subroutine readhead( &
  & cfile    , &
  & pN       , pS       , pW       , pE       , &
  & kcol     , klin     , &
  & kcmpr    , krect )
  
  ! Read required info from header file
  implicit none
  
  ! arguments
  character(len=120), INTENT(IN) :: cfile
  real, optional                 :: pN, pS, pW, pE
  integer, optional              :: kcol, klin
  integer, optional              :: kcmpr, krect

  ! local variables
  character(len=120)             :: chead
  character(len=100)             :: cline, cval
  integer                        :: ios, ipos
  
  ! set to nonsense value
  if (present(pN)) pN = huge(pN)
  if (present(pS)) pS = huge(pS)
  if (present(pW)) pW = huge(pW)
  if (present(pE)) pE = huge(pE)
  if (present(kcol)) kcol = huge(kcol)
  if (present(klin)) klin = huge(klin)
  kcmpr = 0   ! assume no compression
  if (present(krect)) krect = huge(krect)
  
  ! Derive name and open file
  chead = cfile(1:index(cfile, ".", BACK=.TRUE.)) // "hdr"
  print *, "Reading header file ", trim(chead)
  open(unit=14, file=chead, status="old", action="read")
  
  do
    read(14,"(a)",iostat=ios) cline
    if (ios /= 0) exit
    
    ! Expected format: 'keyword: value'
    ipos = index(cline,":")
    if (ipos > 1) then
      ios = 0
      cval = adjustl(cline(ipos+1:))
      select case (cline(1:ipos-1))
        case ("north")
          if (present(pN)) read(cval, "(f10.0)", iostat=ios) pN
        case ("south")
          if (present(pS)) read(cval, "(f10.0)", iostat=ios) pS
        case ("west")
          if (present(pW)) read(cval, "(f10.0)", iostat=ios) pW
        case ("east")
          if (present(pE)) read(cval, "(f10.0)", iostat=ios) pE
        case ("rows")
          if (present(klin)) read(cval, "(i10)", iostat=ios) klin
        case ("cols")
          if (present(kcol)) read(cval, "(i10)", iostat=ios) kcol
        case ("compress")
          if (present(kcmpr)) read(cval, "(i10)", iostat=ios) kcmpr
        case ("recordtype")
          if (present(krect)) then
            select case (trim(cval))
              case ("integer 8 bits", "integer 8 bytes")
                krect = NF90_BYTE
              case ("integer 16 bits", "integer 16 bytes")
                krect = NF90_SHORT
              case default
                ios=1
            endselect
          endif
      endselect
      if (ios /= 0) then
        print *, "Failed to interpret ", trim(cline)
        error stop
      endif
    endif
  enddo
    
  ! Close file
  close(14)
  
end subroutine readhead

!---------------------------------------------------------------------------------------------------

subroutine writehead( &
  & cfile_in , cfile_out, &
  & pN       , pS       , pW       , pE       , &
  & kcol     , klin     , &
  & kcmpr    , krect    )
  
  ! Write info to header file
  implicit none
  
  ! arguments
  character(len=120), INTENT(IN) :: cfile_in
  character(len=120), INTENT(IN) :: cfile_out
  real, optional                 :: pN, pS, pW, pE
  integer, optional              :: kcol, klin
  integer, optional              :: kcmpr, krect

  ! local variables
  character(len=120)             :: chead_in, chead_out
  character(len=100)             :: cline_in, ckey, cval, cline_out
  integer                        :: ios, ipos
  
  ! Derive names and open files
  chead_in = cfile_in(1:index(cfile_in, ".", BACK=.TRUE.)) // "hdr"
  open(unit=14, file=chead_in, status="old", action="read")
  chead_out = cfile_out(1:index(cfile_out, ".", BACK=.TRUE.)) // "hdr"
  print *, "Writing header file ", trim(chead_out), " based on ", trim(chead_in)
  open(unit=15, file=chead_out, action="write")
  
  do
    read(14,"(a)",iostat=ios) cline_in
    if (ios /= 0) exit
    
    ! Expected format: 'keyword: value'
    cline_out = ""
    cval = ""
    ipos = index(cline_in,":")
    if (ipos > 1) then
      ios = 0
      ckey = cline_in(1:ipos)
      select case (cline_in(1:ipos-1))
        case ("north")
          if (present(pN)) write(cval, *, iostat=ios) pN
        case ("south")
          if (present(pS)) write(cval, *, iostat=ios) pS
        case ("west")
          if (present(pW)) write(cval, *, iostat=ios) pW
        case ("east")
          if (present(pE)) write(cval, *, iostat=ios) pE
        case ("rows")
          if (present(klin)) write(cval, "(i10)", iostat=ios) klin
        case ("cols")
          if (present(kcol)) write(cval, "(i10)", iostat=ios) kcol
        case ("compress")
          if (present(kcmpr)) write(cval, "(i10)", iostat=ios) kcmpr
        case ("recordtype")
          if (present(krect)) then
            select case (krect)
              case (NF90_BYTE)
                cval = "integer 8 bits"
              case (NF90_SHORT)
                cval = "integer 16 bits"
              case default
                ios=1
            endselect
          endif
      endselect
      if (ios /= 0) then
        print *, "Failed to update line", trim(cline_in)
        error stop
      endif
    endif
    if (len_trim(cval) == 0) then
      cline_out = cline_in
    else
      cline_out = trim(ckey) // " " // adjustl(trim(cval))
    endif
    
    write(15, "(a)") trim(cline_out)
  enddo
    
  ! Close files
  close(14)
  close(15)
  
end subroutine writehead

!---------------------------------------------------------------------------------------------------
end module header_mod
