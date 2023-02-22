program ecosg_bin2nc
  ! Convert a binary file to netcdf
  ! modules and options
  use netcdf
  use header_mod
  implicit none
  
  ! variable declarations
  character(len=512)      :: carg                           ! reading of arguments
  character(len=512)      :: binfile                        ! name of binary input file
  character(len=512)      :: outfile                        ! path of netcdf output file
  character(len=512)      :: varname                        ! variable name in netcdf file
  integer                 :: nx, ny, nlines, j              ! dimensions and counters
  integer                 :: ncid, xdid, ydid, &            ! for writing to netcdf
                           & varid, lonid, latid, projid
  integer                 :: icompress, irect, nbyte        ! is file compressed and record type (from header)
  integer*1, allocatable  :: i1vals(:)                      ! For reading 1 byte integers
  integer*2, allocatable  :: i2vals(:)                      ! For reading 2 byte integers
  real, allocatable       :: zvals(:)                       ! For lats & lons
  real                    :: zN, zS, zW, zE                 ! lon/lat limits
  
  ! Interpret arguments, and read header
  if (iargc() == 3) then
    ! binary input file
    call getarg(1, binfile)
    
    ! output netcdf file, and variable name
    call getarg(2, outfile)
    call getarg(3, varname)
  else
    call getarg(0, carg)
    print*, "Usage : ",trim(carg), " <file_in> <nc_file_out> <var_name>"
    stop
  endif
  
  ! read header
  call readhead(binfile, pN=zN, pS=zS, pW=zW, pE=zE, kcol=nx, klin=ny, kcmpr=icompress, krect=irect)
  if (icompress /= 0) then
    print *, "Program is designed to work with uncompressed files, but the header suggests this file is compressed"
    error stop
  endif
  select case (irect)
    case (NF90_BYTE)
      nbyte=1
    case (NF90_SHORT)
      nbyte=2
    case default
      print *, "Unsupported data type: ", irect
      error stop
  endselect
  
  ! create netcdf file
  call check( nf90_create(outfile, cmode=(nf90_clobber+nf90_classic_model+nf90_hdf5), ncid=ncid) )
  call check( nf90_def_dim(ncid, "lon", nx, xdid) )
  call check( nf90_def_dim(ncid, "lat", ny, ydid) )
  call check( nf90_def_var(ncid, "Latitude_Longitude", NF90_CHAR, projid) )
  call check( nf90_def_var(ncid, varname, irect, (/xdid,ydid/), varid) )
  call check( nf90_def_var(ncid, "lat", NF90_FLOAT, (/ydid/), latid) )
  call check( nf90_def_var(ncid, "lon", NF90_FLOAT, (/xdid/), lonid) )
  call check( nf90_put_att(ncid, projid, "grid_mapping_name", "latitude_longitude") )
  call check( nf90_put_att(ncid, varid, "grid_mapping", "Latitude_Longitude") )
  call check( nf90_put_att(ncid, latid, "units", "degrees_north") )
  call check( nf90_put_att(ncid, lonid, "units", "degrees_east") )
  call check( nf90_def_var_deflate(ncid = ncid, varID = varid, shuffle = 1 , deflate = 1, deflate_level = 1) )
  call check( nf90_def_var_deflate(ncid = ncid, varID = latid, shuffle = 1 , deflate = 1, deflate_level = 1) )
  call check( nf90_def_var_deflate(ncid = ncid, varID = lonid, shuffle = 1 , deflate = 1, deflate_level = 1) )
  call check( nf90_enddef(ncid) )
    
  ! add coordinates lat & lon
  allocate(zvals(ny))
  do j = 1, ny
    zvals(j) = zN - (j-0.5)*(zN-zS)/ny
  enddo
  call check( nf90_put_var(ncid, latid, zvals) )
  deallocate(zvals)
  allocate(zvals(nx))
  do j = 1, nx
    zvals(j) = zW + (j-0.5)*(zE-zW)/nx
  enddo
  call check( nf90_put_var(ncid, lonid, zvals) )
  deallocate(zvals)
  
  ! open binary file, read from binary and put in netcdf file per n lines
  nlines=720
  open (unit=13, file=binfile, form='unformatted', access='direct', recl=nx*nlines*nbyte, status="old", convert='big_endian')
  select case (irect)
    case (NF90_BYTE)
      allocate(i1vals(nx*nlines))
      do j = 1, ny/nlines, 1
        print *, j*nlines, " of ", ny
        read(unit=13, rec=j) i1vals
        call check( nf90_put_var(ncid, varid, i1vals, start=(/1,(j-1)*nlines+1/), count=(/nx,nlines/)) )
      enddo
      deallocate(i1vals)
    case (NF90_SHORT)
      allocate(i2vals(nx*nlines))
      do j = 1, ny/nlines, 1
        print *, j*nlines, " of ", ny
        read(unit=13, rec=j) i2vals
        call check( nf90_put_var(ncid, varid, i2vals, start=(/1,(j-1)*nlines+1/), count=(/nx,nlines/)) )
      enddo
      deallocate(i2vals)
  endselect
  
  ! close binary and netcdf file
  close(13)
  call check( nf90_close(ncid) )
  
  contains
    subroutine check(status)
      integer, intent (in) :: status
      
      if(status /= nf90_noerr) then 
        print *, trim(nf90_strerror(status))
        stop "Stopped"
      end if
    end subroutine check
  
end program
