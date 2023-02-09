program mod_ecosg_cover
  ! Modify cover types in ECOCLIMAP-SG binary file (e.g. urban to grass, or any nature type to tropical trees)
  implicit none
  
  ! variable declarations
  character(len=512)      :: binfile                        ! name of binary input file
  character(len=512)      :: outfile                        ! path of netcdf output file
  integer                 :: nx, ny, nlines, j, jx, jy, jp  ! dimensions and counters
  integer*1, allocatable  :: ivals(:)                       ! for reading 1 byte integers
  real                    :: zbN, zbS, zbW, zbE             ! block definition lat/lon
  real                    :: zN, zS, zlat, zlon             ! lat/lon calulcations
  
  ! hard-coded paths and dimensions (could be read from *.hdr file)
  binfile = "ecosg_final_map.dir"
  outfile = "ecosg_final_map_mod.dir"
  nx = 360 * 360
  ny = 180 * 360
  
  ! which block to modify
  zbN = 52.2
  zbS = 51.8
  zbW = 5.05
  zbE = 5.25
  
  ! open binary files and read, modify in subdomain, put in new binary. Work per n lines
  nlines=800
  allocate(ivals(nx*nlines))
  open (unit=13, file=binfile, form='unformatted', access='direct', recl=nx*nlines, status="old", convert='big_endian')
  open (unit=14, file=outfile, form='unformatted', access='direct', recl=nx*nlines, status="new", convert='big_endian')
  do j = 1, ny/nlines, 1
    print *, j*nlines, " of ", ny
    read(unit=13, rec=j) ivals
    
    ! Would modify globally from urban to grass
    ! where(ivals >= 24)
    !   ivals = 17
    ! endwhere
    
    ! modify in a block, assuming 360 points per degree, and global file, going N -> S, lets make it tropical!
    zN = 90.0 - ((j-1)*nlines+0.5)/360.0
    zS = 90.0 - (j*nlines-0.5)/360.0
    if ( zN >= zbS .and. zS <= zbN ) then
      ! read block and block we want to modify overlap (in lat), now check all points (surely this can be done a lot smarter)
      do jy = 1, nlines, 1
        zlat = 90.0 - ((j-1)*nlines + jy-0.5)/360.0
        if (zlat <= zbN .and. zlat >= zbS) then
          do jx = 1, nx, 1
            zlon = -180.0 + (jx-0.5)/360.0
            jp = (jy-1)*nx + jx
            if (zlon >= zbW .and. zlon <= zbE .and. ivals(jp) >= 4 .and. ivals(jp) <= 23) then
              print *, "Modify (", zlon, ",", zlat, ")", ivals(jp), "to" , 11
              ivals(jp) = 11
            endif
          enddo
        endif
      enddo
    endif
    write(unit=14, rec=j) ivals
  enddo
  close(13)
  close(14)
  deallocate(ivals)

end program
