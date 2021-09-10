
#!/bin/bash

EXP='FPS12'
FIRST_MONTH=01
LAST_MONTH=12

if [[ "$EXP" == "FPS12" ]]; then
    # https://en.wikipedia.org/wiki/Module:Location_map/data/Alps
    indir0='/nobackup/rossby25/proj/rossby/joint_exp/eucp/HCLIM38h1_FPSconvection_ALADIN_ERAi/archive'
    experiment='FPS12_HCLIM38h1_FPSconvection_ALADIN_ERAi'
    experiment_cmorized='12km'
    FIRST_YEAR=1999
    LAST_YEAR=1999 #2009 #2014 available but 2009 to consistent with FPS3
    lonmin='4.5'
    lonmax='17'
    latmin='42.75'
    latmax='48.5'
    VAR_LIST=('tas_fp' )
    #VAR_LIST=('ta500_fp' 'ta700_fp' 'ta850_fp' 'ta950_fp' \
    #	'hus500_fp' 'hus700_fp' 'hus850_fp' 'hus950_fp' \
    #	'ua500_fp' 'ua700_fp' 'ua850_fp' 'ua950_fp' \
    #	'va500_fp' 'va700_fp' 'va850_fp' 'va950_fp' \
    #	'phi500_fp' 'phi700_fp' 'phi850_fp' 'phi950_fp')

elif [[ "$EXP" == "FPS3" ]]; then 
    indir0='/nobackup/rossby25/proj/rossby/joint_exp/eucp/HCLIM38h1_FPSconvection_AROME_ALD_ERAi_sm/archive'
    experiment='FPS3_HCLIM38h1_FPSconvection_AROME_ALD_ERAi_sm' # original
    experiment_cmorized='3km'
    #indir='/nobackup/rossby25/proj/rossby/joint_exp/eucp/CORDEX-FPSCONV/output/ALP-3/HCLIMcom/ECMWF-ERAINT/evaluation/r1i1p1/HCLIMcom-HCLIM38-AROME/fpsconv-x2yn2-v1/1hr/tas' #cmorized
    #experiment='ALP-3_ECMWF-ERAINT_evaluation_r1i1p1_HCLIMcom-HCLIM38-AROME_fpsconv-x2yn2-v1_1hr' # cmorized
    FIRST_YEAR=1999
    LAST_YEAR=2009
    lonmin='9'
    lonmax='13'
    latmin='45.5'
    latmax='47.7'
    VAR_LIST=('tas_fp' 'prrain_fp' 'prsnow_fp' 'prgrpl_fp')
fi

for ivar in ${VAR_LIST[@]} ; do

  yy=${FIRST_YEAR}
  while [ ${yy} -le ${LAST_YEAR} ]; do

    mm=${FIRST_MONTH}
    while [ ${mm} -le ${LAST_MONTH} ]; do

      if [[ ${#mm} -lt 2 ]] ; then
	mm2d="0${mm}"
      else
	mm2d="${mm}"
      fi
      echo The current year-month is: $yy $mm2d

      if [[ "$EXP" == "FPS12" ]]; then
    	indir='/nobackup/rossby25/proj/rossby/joint_exp/eucp/HCLIM38h1_FPSconvection_ALADIN_ERAi/archive/'${yy}/${mm2d}'/01/00/'

      elif [[ "$EXP" == "FPS3" ]]; then 
	indir='/nobackup/rossby25/proj/rossby/joint_exp/eucp/HCLIM38h1_FPSconvection_AROME_ALD_ERAi_sm/archive/'${yy}/${mm2d}'/01/00/'
      fi

      indir=${indir0}/${yy}/${mm2d}'/01/00'
      outdir='/nobackup/rossby26/users/sm_fuxwa/AI'
      infile=${ivar}_${experiment}_${yy}${mm2d}'0100.nc' 
      outfile=${ivar}_${experiment}_${yy}${mm2d}'0100_smalldomain.nc'

      cdo sellonlatbox,$lonmin,$lonmax,$latmin,$latmax $indir/$infile $outdir/$outfile

      let mm=mm+1
      #while [[ ${#mm} -lt 2 ]] ; do
      #  mm="0${mm}"
      #done

    done #mm
    let yy=yy+1 

  done #yy

  # Merge nc files
  outfile_all=${ivar}_${experiment}_*'0100_smalldomain.nc'
  outfile_merge=${ivar}_${experiment}_${FIRST_YEAR}${FIRST_MONTH}_${LAST_YEAR}${LAST_MONTH}'.nc'
  outfile_merge_cmorized=${ivar}_${experiment_cmorized}_${FIRST_YEAR}${FIRST_MONTH}_${LAST_YEAR}${LAST_MONTH}'.nc'
  if [ -f $outdir/$outfile_merge ]; then
    rm  $outdir/$outfile_merge
  fi
  cdo mergetime $outdir/$outfile_all $outdir/$outfile_merge 
  rm $outdir/$outfile_all
  mv $outdir/$outfile_merge  $outdir/$outfile_merge_cmorized

done #ivar


if [[ "$EXP" == "FPS3" ]]; then
    outfile_prrain='prrain_fp'_${experiment}_${FIRST_YEAR}${FIRST_MONTH}_${LAST_YEAR}${LAST_MONTH}'.nc'
    outfile_prsnow='prsnow_fp'_${experiment}_${FIRST_YEAR}${FIRST_MONTH}_${LAST_YEAR}${LAST_MONTH}'.nc'
    outfile_prgrpl='prgrpl_fp'_${experiment}_${FIRST_YEAR}${FIRST_MONTH}_${LAST_YEAR}${LAST_MONTH}'.nc'
    outfile_pr='pr_fp'_${experiment}_${FIRST_YEAR}${FIRST_MONTH}_${LAST_YEAR}${LAST_MONTH}'.nc'
    outfile_pr_cmorized='pr'_${experiment}_${FIRST_YEAR}${FIRST_MONTH}_${LAST_YEAR}${LAST_MONTH}'.nc'
    cdo enssum $outdir/$outfile_prrain $outdir/$outfile_prsnow $outdir/$outfile_prgrpl $outdir/$outfile_pr
    rm $outdir/$outfile_prrain $outdir/$outfile_prsnow $outdir/$outfile_prgrpl 
    mv $outdir/$outfile_pr  $outdir/$outfile_pr_cmorized
fi
