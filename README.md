# ECOCLIMAP-SG tools
A collection of scripts and programs to modify and work with ECOCLIMAP-SG binary files  
See the [ECOCLIMAP-SG wiki](https://opensource.umr-cnrm.fr/projects/ecoclimap-sg/wiki) for general ECOCLIMAP-SG info.


## Building

To compile, simply run:
``` bash
./build.sh [<makefile>]
```
This will load the required modules and call the makefiles for all `*.mk` files. Optionally you can specify 1 or more makefiles as argument to only run those makefiles.
The `config.ECMWF.atos` file contains some paths and flags and is included in the makefiles.

After successful compilation and linking the executable will be moved to `$HOME/$USER/bin`.


## Modify ECOCLIMAP-SG COVER

The ECOCLIMAPS-SG files are large binary files. The `mod_ecosg_cover` program reads the COVER binary file, modifies it in an area and writes out a new binary file.


## Uncompress

The binary files of ECOCLIMAP-SG are compressed (except the cover file). This can be recognized by the `compress: 1` keyword in the header files.  
The compression consists of counting the number of subsequent points with missing values (say Nmiss) and storing this in the files as `4000+Nmiss`.  
In addition the files contain both the value (e.g. LAI, tree height) and the cover type in a 2-byte integer (big-endian) and stored as:
```
multitype_value = COVER*100 + value
```
So, if there are 33 cover types, the values in the files should be between 100 and 3399, but 0 is used as a missing value. In the SURFEX code (V8.1) the cover type is set to 0 if the point value is 0 in the uncompress step. To get identical values when feeding the uncompressed files to SURFEX, the same rule should be applied.  

### Uncompress with ECOCLIMAP tool

A tool to uncompress the files can be downloaded from the [ECOCLIMAP-SG wiki](https://opensource.umr-cnrm.fr/projects/ecoclimap-sg/wiki). Simply run `make` to compile. Then run:
``` bash
uncompress_file.exe LAI_1215_c.dir unzip_LAI_1215_c.dir [cover_LAI_1215_c.dir] [rows=50400 cols=129600]
```
Number of rows by default assumes full globe at 300m. Cover is hidden as described above in the compressed files and can be written to a separate file. After uncompressing the cover is not contained in the file anymore, and data are 8-bit instead 16-bit integers.
For further processing the header files need to be adapted (`compress:0`; `recordtype: integer 8 bits`), e.g.:
``` bash
sed -e 's/^compress.*$/compress: 0/' -e 's/^recordtype.*$/recordtype: integer 8 bits/' <header_in> > <header_out>
```
However, these files, when used in PGD need to be read as `DIRECT` and all vegetation types, and later patch types, will then have the same properties.

### Uncompress, preserve multitype and extract subdomain

The original ECOCLIMAP uncompress tool was modified to:
* read properties from the *.hdr header files
* preserve the multitype feature, so DIRTYP reading option can be used
* extract a subdomain
* set points to missing if value is missing, but has a cover type
* write an updated header file
``` bash
uncompress_file_multitype_subdomain <file_in> <file_out> [N=<North> S=<South> W=<West> E=<East>]
```


## Convert to NetCDF

The `ecosg_bin2nc` program can be used to convert a binary file to a basic NetCDF4 file.
Note that the files are very large, and to view them you first might want to cut out a selection, for example:
``` bash
ncks -d lon,65000,68000 -d lat,12500,15500 ecosg_COVER.nc ecosg_COVER_subdomain.nc
```


## Uncompress

To use the tools the ECOCLIMAP-SG files must be uncompressed. 

## Caveats and assumptions
* longitude runs from -180 to 180
* The tools and scripts are written for the ECMWF HPC, so will need some work if you want to use them elsewehere
