#!/usr/bin/env bash
set -e

# load environment
module load prgenv/gnu netcdf4

# Build all makefiles specified as arguments, or all *.mk
if [ $# -eq 0 ]; then
  makefiles='*.mk'
else
  makefiles="$@"
fi
for ff in $makefiles; do
  echo "Building $ff"
  make -f $ff
  echo ""
done
echo "Done!"
