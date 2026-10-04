#!/bin/bash -x
set -u

# =========================
# User variables
# =========================

SPACE="fsaverage6"
BASEDIR="$HOME/Desktop/f/NCGP/data/derivatives"
MASK="localizer"

SURFDIR="$BASEDIR/freesurfer/$SPACE/SUMA"
DATAROOT="$BASEDIR/LDC/group/fmriprep/SPM_GLM"
CODEDIR="$HOME/Desktop/f/NCGP/data/scripts"
VIEWDIR="$CODEDIR/suma_viz/views"

RANGE="0 11"
CMAP="plasma_r.1D.cmap"
SURFACE="inf_200"

SLEEP_START_SUMA="10"
SLEEP_AFTER_VIEW="5"
SLEEP_AFTER_LOAD="5"
SLEEP_AFTER_KEY="5"
SLEEP_AFTER_SAVE="5"
SLEEP_AFTER_KILL="5"

DSET_TFCE_0002="TFCE_log_pFDR_0002+orig.niml.dset"
DSET_TFCE_0001="TFCE_log_pFDR_0001+orig.niml.dset"
DSET_INTERSECTION="intersection_TFCE_log_pFDR+orig.niml.dset"
DSET_INTERSECTION_WEIGHT_BY_SESSDIFF="intersection_weightBySessdiff_TFCE_log_pFDR+orig.niml.dset"
DSET_INTERSECTION_WEIGHT_BY_POSTCONTRAST="intersection_weightByPostcontrast_TFCE_log_pFDR+orig.niml.dset"

DSET_BASENAME="$DSET_TFCE_0001"
OUTPUT_TAG="TFCE_log_pFDR_0001"

DSET_R="$DATAROOT/hemi-R_mask-${MASK}/$DSET_BASENAME"
DSET_L="$DATAROOT/hemi-L_mask-${MASK}/$DSET_BASENAME"

OUT="$DATAROOT/SUMAviews_mask-${MASK}_${OUTPUT_TAG}"

mkdir -p "$OUT"

for HEMI in R L; do

  if [ "$HEMI" = "R" ]; then
    HEMI_SUMA="rh"
    DSET="$DSET_R"
  else
    HEMI_SUMA="lh"
    DSET="$DSET_L"
  fi

  DATADIR="$DATAROOT/hemi-${HEMI}_mask-${MASK}"
  SPEC="$SURFDIR/${SPACE}_${HEMI_SUMA}.spec"

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
  sleep "$SLEEP_START_SUMA"

  DriveSuma -com viewer_cont -load_view "$VIEWDIR/NCGP_${HEMI_SUMA}_lateral_white.niml.vvs"
  sleep "$SLEEP_AFTER_VIEW"

  DriveSuma -com surf_cont \
    -switch_surf "$SURFACE" \
    -load_dset "$DSET" \
    -load_cmap "$CMAP" \
    -I_range "$RANGE"

  DriveSuma -com viewer_cont -key a
  sleep "$SLEEP_AFTER_LOAD"

  DriveSuma -com viewer_cont -key 'r'
  sleep "$SLEEP_AFTER_KEY"

  DriveSuma -com recorder_cont -save_as "$OUT/${HEMI_SUMA}_lateral.png" -save_all
  sleep "$SLEEP_AFTER_SAVE"

  DriveSuma -com kill_suma
  wait "$SUMA_PID" 2>/dev/null || true
  sleep "$SLEEP_AFTER_KILL"


  # =========================
  # 2. Medial view
  # =========================

  suma -niml -spec "$SPEC" &
  SUMA_PID=$!
  sleep "$SLEEP_START_SUMA"

  DriveSuma -com viewer_cont -load_view "$VIEWDIR/NCGP_${HEMI_SUMA}_medial_white.niml.vvs"
  sleep "$SLEEP_AFTER_VIEW"

  DriveSuma -com surf_cont \
    -switch_surf "$SURFACE" \
    -load_dset "$DSET" \
    -load_cmap "$CMAP" \
    -I_range "$RANGE"

  DriveSuma -com viewer_cont -key a
  sleep "$SLEEP_AFTER_LOAD"

  DriveSuma -com viewer_cont -key 'r'
  sleep "$SLEEP_AFTER_KEY"

  DriveSuma -com recorder_cont -save_as "$OUT/${HEMI_SUMA}_medial.png" -save_all
  sleep "$SLEEP_AFTER_SAVE"

  DriveSuma -com kill_suma
  wait "$SUMA_PID" 2>/dev/null || true
  sleep "$SLEEP_AFTER_KILL"


  # =========================
  # 3. Ventral view
  # =========================

  suma -niml -spec "$SPEC" &
  SUMA_PID=$!
  sleep "$SLEEP_START_SUMA"

  DriveSuma -com viewer_cont -load_view "$VIEWDIR/NCGP_${HEMI_SUMA}_ventral_white.niml.vvs"
  sleep "$SLEEP_AFTER_VIEW"

  DriveSuma -com surf_cont \
    -switch_surf "$SURFACE" \
    -load_dset "$DSET" \
    -load_cmap "$CMAP" \
    -I_range "$RANGE"

  DriveSuma -com viewer_cont -key a
  sleep "$SLEEP_AFTER_LOAD"

  DriveSuma -com viewer_cont -key 'r'
  sleep "$SLEEP_AFTER_KEY"

  DriveSuma -com recorder_cont -save_as "$OUT/${HEMI_SUMA}_ventral.png" -save_all
  sleep "$SLEEP_AFTER_SAVE"

  DriveSuma -com kill_suma
  wait "$SUMA_PID" 2>/dev/null || true
  sleep "$SLEEP_AFTER_KILL"


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