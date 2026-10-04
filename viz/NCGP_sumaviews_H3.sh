#!/bin/bash -x
set -u

SPACE="fsaverage6"
BASEDIR="$HOME/Desktop/f/NCGP/data/derivatives"
TASK="localizer"
RANGE="1.6 10"

SURFDIR="$BASEDIR/freesurfer/$SPACE/SUMA"
DATAROOT="$BASEDIR/SPM_GLM/group/fmriprep"
CODEDIR="$HOME/Desktop/f/NCGP/data/scripts"
VIEWDIR="$CODEDIR/suma_viz/views"

OUT="$DATAROOT/task-${TASK}_SUMAviews"
mkdir -p "$OUT"

for HEMI in R L; do

  if [ "$HEMI" = "R" ]; then
    HEMI_SUMA="rh"
  else
    HEMI_SUMA="lh"
  fi

  DATADIR="$DATAROOT/task-${TASK}_hemi-${HEMI}_smooth-S6"
  SPEC="$SURFDIR/${SPACE}_${HEMI_SUMA}.spec"
  DSET="$DATADIR/SpmT_0001+orig.niml.dset"

  echo "Running hemisphere: $HEMI"
  echo "SUMA hemisphere: $HEMI_SUMA"
  echo "SPEC: $SPEC"
  echo "DSET: $DSET"
  echo "OUT: $OUT"

  rm -f "$OUT/${HEMI_SUMA}"*.png


  # =========================
  # 1. Lateral view
  # =========================

  suma -niml -spec "$SPEC" &
  SUMA_PID=$!
  sleep 10

  DriveSuma -com viewer_cont -load_view "$VIEWDIR/NCGP_${HEMI_SUMA}_lateral_white.niml.vvs"
  sleep 5

  DriveSuma -com surf_cont \
    -switch_surf inf_200 \
    -load_dset "$DSET" \
    -load_cmap plasma_r.1D.cmap \
    -I_range "$RANGE"

  DriveSuma -com viewer_cont -key a
  sleep 5

  DriveSuma -com viewer_cont -key 'r'
  sleep 5

  DriveSuma -com recorder_cont -save_as "$OUT/${HEMI_SUMA}_lateral.png" -save_all
  sleep 5

  DriveSuma -com kill_suma
  wait "$SUMA_PID" 2>/dev/null || true
  sleep 5


  # =========================
  # 2. Medial view
  # =========================

  suma -niml -spec "$SPEC" &
  SUMA_PID=$!
  sleep 10

  DriveSuma -com viewer_cont -load_view "$VIEWDIR/NCGP_${HEMI_SUMA}_medial_white.niml.vvs"
  sleep 5

  DriveSuma -com surf_cont \
    -switch_surf inf_200 \
    -load_dset "$DSET" \
    -load_cmap plasma_r.1D.cmap \
    -I_range "$RANGE"

  DriveSuma -com viewer_cont -key a
  sleep 5

  DriveSuma -com viewer_cont -key 'r'
  sleep 5

  DriveSuma -com recorder_cont -save_as "$OUT/${HEMI_SUMA}_medial.png" -save_all
  sleep 5

  DriveSuma -com kill_suma
  wait "$SUMA_PID" 2>/dev/null || true
  sleep 5


  # =========================
  # 3. Ventral view
  # =========================

  suma -niml -spec "$SPEC" &
  SUMA_PID=$!
  sleep 10

  DriveSuma -com viewer_cont -load_view "$VIEWDIR/NCGP_${HEMI_SUMA}_ventral_white.niml.vvs"
  sleep 5

  DriveSuma -com surf_cont \
    -switch_surf inf_200 \
    -load_dset "$DSET" \
    -load_cmap plasma_r.1D.cmap \
    -I_range "$RANGE"

  DriveSuma -com viewer_cont -key a
  sleep 5

  DriveSuma -com viewer_cont -key 'r'
  sleep 5

  DriveSuma -com recorder_cont -save_as "$OUT/${HEMI_SUMA}_ventral.png" -save_all
  sleep 5

  DriveSuma -com kill_suma
  wait "$SUMA_PID" 2>/dev/null || true
  sleep 5


  # =========================
  # 4. Rename saved screenshots
  # =========================

  mv "$OUT/${HEMI_SUMA}_lateral.00000.png" "$OUT/${HEMI_SUMA}_lateral.png"
  mv "$OUT/${HEMI_SUMA}_medial.00000.png" "$OUT/${HEMI_SUMA}_medial.png"
  mv "$OUT/${HEMI_SUMA}_ventral.00000.png" "$OUT/${HEMI_SUMA}_ventral.png"


  # =========================
  # 5. Trim images
  # =========================

  convert "$OUT/${HEMI_SUMA}_lateral.png" -trim +repage "$OUT/${HEMI_SUMA}_lateral_trim.png"
  convert "$OUT/${HEMI_SUMA}_medial.png" -trim +repage "$OUT/${HEMI_SUMA}_medial_trim.png"
  convert "$OUT/${HEMI_SUMA}_ventral.png" -trim +repage "$OUT/${HEMI_SUMA}_ventral_trim.png"


  # =========================
  # 6. Arrange hemisphere
  # =========================

  convert \
    "$OUT/${HEMI_SUMA}_lateral_trim.png" \
    "$OUT/${HEMI_SUMA}_medial_trim.png" \
    -background white \
    -gravity center \
    -append \
    "$OUT/${HEMI_SUMA}.lat_med.png"

  if [ "$HEMI_SUMA" = "lh" ]; then
    convert \
      "$OUT/${HEMI_SUMA}_ventral_trim.png" \
      "$OUT/${HEMI_SUMA}.lat_med.png" \
      -background white \
      -gravity center \
      +append \
      "$OUT/${HEMI_SUMA}.final.png"
  else
    convert \
      "$OUT/${HEMI_SUMA}.lat_med.png" \
      "$OUT/${HEMI_SUMA}_ventral_trim.png" \
      -background white \
      -gravity center \
      +append \
      "$OUT/${HEMI_SUMA}.final.png"
  fi

done

convert \
  "$OUT/lh.final.png" \
  "$OUT/rh.final.png" \
  -background white \
  -gravity center \
  +append \
  "$OUT/B.final.png"

echo "Done. Final bilateral image:"
echo "$OUT/B.final.png"