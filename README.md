# ECOCLIMAP-SG tools
A collection of scripts and programs to modify and work with ECOCLIMAP-SG binary files


## Building

To compile, simply run:
``` bash
./build.sh [<makefile>]
```
This will load the required modules and call the makefiles for all `*.mk` files. Optionally you can specify 1 or more makefiles as argument to only run those makefiles.
The `config.ECMWF.atos` file contains some paths and flags and is included in the makefiles.

After successful compilation and linking the executable will be moved to `$HOME/$user/bin`.


## Modify ECOCLIMAP-SG

The ECOCLIMAPS-SG files are large binary files. The `mod_ecosg_cover` program reads the COVER binary file, modifies it in an area and writes out a new binary file.


## Convert to NetCDF

The `ecosg_bin2nc` program can be used to convert a binary file to a basic NetCDF4 file.
Note that the files are very large, and to view them you first might want to cut out a selection, for example:
``` bash
ncks -d lon,65000,68000 -d lat,12500,15500 ecosg_COVER.nc ecosg_COVER_subdomain.nc
```


## Uncompress

To use the tools the ECOCLIMAP-SG files must be uncompressed. A tool to uncompress the files can be downloaded from the [ECOCLIMAP-SG wiki](https://opensource.umr-cnrm.fr/projects/ecoclimap-sg/wiki). Simply run `make` to compile. Then run:
``` bash
uncompress_file.exe LAI_1215_c.dir unzip_LAI_1215_c.dir [cover_LAI_1215_c.dir] [rows=50400 cols=129600]
```
Number of rows by default assumes full globe at 300m. Cover is hidden in the compressed files and can be written to a separate file. After uncompressing the cover is not contained in the file anymore, and data are 8-bit instead 16-bit integers.
For further processing the header files need to be adapted (`compress:0`; `recordtype: integer 8 bits`), e.g.:
``` bash
sed -e 's/^compress.*$/compress: 0/' -e 's/^recordtype.*$/recordtype: integer 8 bits/' <header_in> > <header_out>
```

## Caveats
* all paths are hard-coded
* all dimensions are hard-coded, could be read from *.hdr files
* extend (N-S) and resolution is hard-coded and/or implicit in some calculations, could be read from *.hdr files
* The tools and scripts are written for the ECMWF HPC, so will need some work if you want to use them elsewehere
