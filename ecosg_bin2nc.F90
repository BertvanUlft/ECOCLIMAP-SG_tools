program ecosg_bin2nc
  ! Convert a binary file to netcdf
  ! modules and options
  use netcdf
  implicit none
  
  ! variable declarations
  character(len=512)      :: binfile                        ! name of binary input file
  character(len=512)      :: outfile                        ! path of netcdf output file
  character(len=512)      :: varname                        ! variable name in netcdf file
  integer                 :: nx, ny, nlines, j              ! dimensions and counters
  integer                 :: ncid, xdid, ydid, &            ! for writing to netcdf
                           & varid, lonid, latid, projid
  integer*1, allocatable  :: ivals(:)                       ! For reading 1 byte integers
  real, allocatable       :: zvals(:)                       ! For lats & lons
  real                    :: zS, zN                         ! South and North limits
  
  ! hard-coded paths etc, nx, ny, zS & zN could be read from *.hdr files
  varname = "COVER"
  binfile = "ecosg_final_map_mod.dir"
  outfile = "ecosg_" // trim(varname) // ".nc"
  zS = -90.0
  zN = 90.0
  nx = 360 * 360
  ny = nint((zN - zS) * 360)
  
  ! create netcdf file
  call check( nf90_create(outfile, cmode=(nf90_clobber+nf90_classic_model+nf90_hdf5), ncid=ncid) )
  call check( nf90_def_dim(ncid, "lon", NX, xdid) )
  call check( nf90_def_dim(ncid, "lat", NY, ydid) )
  call check( nf90_def_var(ncid, "Latitude_Longitude", NF90_CHAR, projid) )
  call check( nf90_def_var(ncid, varname, NF90_BYTE, (/xdid,ydid/), varid) )
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
    
  ! add coordinates lat & lon, assume file is from -180 to 180
  allocate(zvals(ny))
  do j = 1, ny
    zvals(j) = zN - (j-0.5)*(zN-(zS))/ny
  enddo
  call check( nf90_put_var(ncid, latid, zvals) )
  deallocate(zvals)
  allocate(zvals(nx))
  do j = 1, nx
    zvals(j) = -180.0 + (j-0.5)*(360.0)/nx
  enddo
  call check( nf90_put_var(ncid, lonid, zvals) )
  deallocate(zvals)
  
  ! open binary file, read from binary and put in netcdf file per n lines
  nlines=800
  allocate(ivals(nx*nlines))
  open (unit=13, file=binfile, form='unformatted', access='direct', recl=nx*nlines, status="old", convert='big_endian')
  do j = 1, ny/nlines, 1
    print *, j*nlines, " of ", ny
    read(unit=13, rec=j) ivals
    call check( nf90_put_var(ncid, varid, ivals, start=(/1,(j-1)*nlines+1/), count=(/nx,nlines/)) )
  enddo
  deallocate(ivals)
  
  ! close binary and netcdf file
  close(13)
  call check( nf90_close(ncid) )
  
  contains
    subroutine check(status)
      integer, intent ( in) :: status
      
      if(status /= nf90_noerr) then 
        print *, trim(nf90_strerror(status))
        stop "Stopped"
      end if
    end subroutine check
  
end program
