#!/usr/bin/env bash

#########
# Notes #
#########

# DF expects everything in the current directory, both RO and writable data.

# Further, it oddly requires *all* the data files to be writable.

# So we make a per-revision copy of the data files with some strategic symlinks
# to avoid copying executables and libraries.

# The only files that upstream says can be carried from release to release are
# savefiles.  Not even init.txt can be carried over.

##############
# Directives #
##############

# SC1090: Can't follow non-constant source.
# shellcheck source=/dev/null

#############
# Kickstart #
#############

cd "$SNAP" || exit

# Are we a new revision?
DF_LAST_REVISION=
if [ -e "$SNAP_USER_DATA"/.df_revision ]; then
  . "$SNAP_USER_DATA"/.df_revision 2>/dev/null || true
fi

# Set up data copy and link farm if needed
if [ "$DF_LAST_REVISION" != "$SNAP_REVISION" ]; then
  # Back up saves
  rm -rf "$SNAP_USER_DATA"/.save
  mv "$SNAP_USER_DATA"/data/save "$SNAP_USER_DATA"/.save 2>/dev/null || true

  # Clear out old files that snapd kindly copied for us
  rm -rf "$SNAP_USER_DATA"/data
  rm -f "$SNAP_USER_DATA"/*

  # Copy data files over, DF needs them to be writable
  cp -r data "$SNAP_USER_DATA"
  mv "$SNAP_USER_DATA"/.save "$SNAP_USER_DATA"/data/save 2>/dev/null || true

  # And finally make symlinks to RO space for rest of files
  for target in libs raw; do
    ln -s "$SNAP/$target" "$SNAP_USER_DATA"
  done

  echo "DF_LAST_REVISION=$SNAP_REVISION" > "$SNAP_USER_DATA"/.df_revision
fi

cd "$SNAP_USER_DATA" || exit

# Work around for bug in Debian/Ubuntu SDL patch.
export SDL_DISABLE_LOCK_KEYS=1

# Launch Dwarf Fortress
pwd
./run_df "$@"

# End of File.
