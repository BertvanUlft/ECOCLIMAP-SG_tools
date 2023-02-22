program uncompress_file_multitype
  
  ! Uncompress a binary ECOCLIMAP-SG file, preserve cover type in file so it can be used in SURFEX (DIRTYP), and optionally cut out a subdomain
  ! Starting point is the uncompress tool from the ecoclimap wiki: https://opensource.umr-cnrm.fr/attachments/download/4796/uncompress_ecosg.tgz

  use header_mod
  implicit none

  real                                 :: zNin, zSin, zWin, zEin     ! lon/lat limits in input file (read from header)
  real                                 :: zNout, zSout, zWout, zEout ! lon/lat limits in output file (lon from -180 to 180, supplied as argument, or same as input file)
  integer*4                            :: ncolin, nlinin             ! number of columns/rows in input file (read from header)
  integer*4                            :: ncolout, nlinout           ! number of columns/rows in input file (calculated)
  integer*4                            :: iNoff, iWoff               ! N and W offset
  integer*4                            :: icompress                  ! is file compressed (read from header)
  integer*4                            :: irect                      ! record type (read from header)
  character(len=120)                   :: carg, cfile_in, cfile_out

  integer*4, dimension(:), allocatable :: nbval                      ! dim nlinin
  integer*2, dimension(:), allocatable :: lread                      ! dim ncolin
  integer*4, dimension(:), allocatable :: lread2                     ! dim ncolin
  integer*2, dimension(:), allocatable :: lwrite                     ! dim ncolout
  integer*4                            :: j, i, k, icpt
  integer*2                            :: i2huge
  integer*1                            :: ok

  ! Valeurs par défaut
  i2huge = huge(i2huge)

  ! Lecture des arguments, and read header
  if (iargc() >= 2 .and. iargc() <= 6) then
    ! fichier en entrée
    call getarg(1, cfile_in)
    print *, "In:  ", trim(cfile_in)
    
    ! read header and initialize output limits
    call readhead(cfile_in, pN=zNin, pS=zSin, pW=zWin, pE=zEin, kcol=ncolin, klin=nlinin, kcmpr=icompress, krect=irect)
    zNout = zNin
    zSout = zSin
    zWout = zWin
    zEout = zEin
    
    ! fichiers en sortie
    call getarg(2, cfile_out)
    print *, "Out: ", trim(cfile_out)
    
    ! arguments optionnels
    do i=3, iargc()
      call getarg(i, carg)
      if (carg(1:2) == 'N=') then
        read(carg(3:),*,iostat=ok) zNout
      elseif (carg(1:2) == 'S=') then
        read(carg(3:),*,iostat=ok) zSout
      elseif (carg(1:2) == 'W=') then
        read(carg(3:),*,iostat=ok) zWout
      elseif (carg(1:2) == 'E=') then
        read(carg(3:),*,iostat=ok) zEout
      else
        print *, "Unknown option: ", carg
        error stop
      endif
      if (ok /= 0) then
        print*, "Erreur lecture argument (",carg,")"
        error stop
      endif
    enddo
  else
    call getarg(0, carg)
    print*, "Usage : ",trim(carg), " <file_in> <file_out> [N=<North> S=<South> W=<West> E=<East>]"
    stop
  endif
  
  ! some checks
  if (icompress /= 1) then
    print *, "Program expects compressed files, but the header suggests this file is not compressed"
    error stop
  endif
  if (irect /= NF90_SHORT) then
    print *, "Program expects 16 bit integers, but the header suggests some other type: ", irect
    error stop
  endif

  ! calculate number of output columns and lines and offset
  nlinout = nint((zNout - zSout)/((zNin - zSin)/nlinin))
  ncolout = nint((zEout - zWout)/((zEin - zWin)/ncolin))
  iNoff   = nint((zNin - zNout)/((zNin - zSin)/nlinin))
  iWoff   = nint((zWout - zWin)/((zEin - zWin)/ncolin))
  
  ! print *, nlinout, ncolout
   print*, iNoff, iWoff
  
  ! Allocations dynamiques
  allocate(nbval(nlinin), stat=ok)
  if (ok /= 0) then
    print*, "Erreur allocation nbval"
    error stop
  endif
  allocate(lread(ncolin), stat=ok)
  if (ok /= 0) then
    print*, "Erreur allocation lread"
    error stop
  endif
  allocate(lread2(ncolin), stat=ok)
  if (ok /= 0) then
    print*, "Erreur allocation lread2"
    error stop
  endif
  allocate(lwrite(ncolout), stat=ok)
  if (ok /= 0) then
    print*, "Erreur allocation lwrite"
    error stop
  endif

  ! En entrée : fichier dit "compressé"
  open(11,file=cfile_in,form='unformatted',access='stream')

  ! En sortie : fichier binaire contenant la matrice des données - entiers sur 2 octet
  open(13,file=cfile_out,form='unformatted',access='direct',recl=ncolout*2, convert='big_endian')

  ! On lit le nombre de valeurs renseignées pour chaque ligne
  read(11) nbval

  ! Boucle sur les lignes
  do j = 1,nlinin
    if (mod(j-1, 1000) == 0) then
      print *, "line ", j,  " of ", nlinin
    endif
    ! Lecture des valeurs binaires en entrée pour une ligne
    lread(:) = 0
    read(11) lread(1:nbval(j))
    
    if (j <= iNoff .or. j > iNoff + nlinout) then
      ! line too far North or South
      cycle
    endif
    
    ! On corrige les valeurs lues négatives
    ! (f90 ne sait pas lire directement les unsigned int)
    lread2(:) = lread(:)
    do k = 1,nbval(j)
      if (lread2(k) < 0) lread2(k) = 32768*2 + lread2(k)
    enddo

    ! Boucle sur les colonnes
    i = 1                      ! indice de l'élément lu dans lread2
    icpt = 1                   ! indice de l'élément écrit dans lwrite
    do while (icpt <= iWoff + ncolout)

      ! Si la valeur lue est valide
      if (lread2(i) < 4000 ) then
        ! On la met dans lwrite à l'indice icpt
        ! Store point if in subdomain
        if (icpt > iWoff .and. icpt <= iWoff + ncolout) then
          ! For points with a zero value, also set type to zero (as is done in src/surfex/SURFEX/uncompress_field.F90)
          ! If this is not done resulting PGD files based on uncompressed files will differ from those based on compressed files
          if (mod(lread2(i), 100) == 0) then
            lwrite(icpt-iWoff) = 0
          else
            if (lread2(i) > i2huge) then
              print *, "Value too large to save in 2 byte integer: ", lread2(i)
              error stop
            else
              lwrite(icpt-iWoff) = lread2(i)
              ! print *, j, icpt, lwrite(icpt-iWoff)
            endif
          endif
        endif
        icpt = icpt + 1
      else
        ! On a (valeur_lue - 4000) valeurs nulles successives
        do k = 1,lread2(i)-4000
          if (icpt > iWoff .and. icpt <= iWoff + ncolout) then
            lwrite(icpt-iWoff) = 0
            ! print *, j, icpt, lwrite(icpt-iWoff)
          endif
          icpt = icpt + 1
        enddo
      endif
      
      ! increase read counter 
      i = i+1
    enddo

    write(13,rec=j-iNoff) lwrite(:)

  enddo

  close(11)
  close(13)

  call writehead(cfile_in, cfile_out, pN=zNout, pS=zSout, pW=zWout, pE=zEout, kcol=ncolout, klin=nlinout, kcmpr=0, krect=irect)

end program uncompress_file_multitype
