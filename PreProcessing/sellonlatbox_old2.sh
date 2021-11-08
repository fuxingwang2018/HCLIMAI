
#!/bin/bash

EXP='FPS12'
FIRST_MONTH=01
LAST_MONTH=12

if [[ "$EXP" == "FPS12" ]]; then
    # https://en.wikipedia.org/wiki/Module:Location_map/data/Alps
    # for tas, pr
    #indir0='/nobackup/rossby25/proj/rossby/joint_exp/eucp/netcdf/HCLIM38-ALADIN/ALP-12/ECMWF-ERAINT/evaluation/'
    #experiment='ALP-12_ECMWF-ERAINT_evaluation_r1i1p1_HCLIMcom-HCLIM38-ALADIN_v1'

    # for ta500..950, hus500..950, ua500..950, va500..950, phi500..950
    indir0='/nobackup/rossby26/users/sm_fuxwa/AI/CORDEX_FPS_ALP12_ERAI_CMORise'
    experiment='ALP-12_ECMWF-ERAINT_evaluation_r1i1p1_HCLIMcom-SMHI-HCLIM38-ALADIN_v1'
    experiment_cmorized='12km'
    FIRST_YEAR=2000
    LAST_YEAR=2009 #2014 available but 2009 to consistent with FPS3, 2009 discarded because of spinup
    #FIRST_DAYHHMM=010000 # tas
    #LAST_DAYHHMM=312300  # tas
    #FIRST_DAYHHMM=010030 # pr
    #LAST_DAYHHMM=312330  # pr
    #FIRST_DAYHHMM=010000 # 3hr
    #LAST_DAYHHMM=312100  # 3hr
    FIRST_DAYHHMM=010000 # 6hr
    LAST_DAYHHMM=311800  # 6hr
    lonmin='4.5'
    lonmax='17'
    latmin='42.75'
    latmax='48.5'
    freq='6hr'
    #VAR_LIST=('tas' ) # pr
    #VAR_LIST=('ta500' 'ta700' 'ta850' 'ta950' \
    #	'hus500' 'hus700' 'hus850' 'hus950' \
    #	'ua500' 'ua700' 'ua850' 'ua950' \
    #	'va500' 'va700' 'va850' 'va950')
    VAR_LIST=('phi500' 'phi700' 'phi850' 'phi950')

elif [[ "$EXP" == "FPS3" ]]; then 
    indir0='/nobackup/rossby25/proj/rossby/joint_exp/eucp/CORDEX-FPSCONV/output/ALP-3/HCLIMcom/ECMWF-ERAINT/evaluation/r1i1p1/HCLIMcom-HCLIM38-AROME/fpsconv-x2yn2-v1/'
    experiment='ALP-3_ECMWF-ERAINT_evaluation_r1i1p1_HCLIMcom-HCLIM38-AROME_fpsconv-x2yn2-v1' 
    experiment_cmorized='3km'
    freq='1hr'
    VAR_LIST=('tas' )  # pr
    FIRST_YEAR=2000 # 1999 available but we discard it for spinup
    LAST_YEAR=2009
    FIRST_DAYHHMM=010000
    LAST_DAYHHMM=312300
    #FIRST_DAYHHMM=010030 # pr
    #LAST_DAYHHMM=312330  # pr
    lonmin='9'
    lonmax='13'
    latmin='45.5'
    latmax='47.7'
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

      let mm=mm+1
      #while [[ ${#mm} -lt 2 ]] ; do
      #  mm="0${mm}"
      #done

    done #mm

    indir=${indir0}/${freq}/${ivar}
    outdir='/nobackup/rossby26/users/sm_fuxwa/AI/'${experiment_cmorized}/${freq}/${ivar}
    infile=${ivar}_${experiment}_${freq}_${yy}${FIRST_MONTH}${FIRST_DAYHHMM}'-'${yy}${LAST_MONTH}${LAST_DAYHHMM}'.nc' 
    outfile=${ivar}_${experiment}_${freq}_${yy}${FIRST_MONTH}${FIRST_DAYHHMM}'-'${yy}${LAST_MONTH}${LAST_DAYHHMM}'_smalldomain.nc'

    cdo sellonlatbox,$lonmin,$lonmax,$latmin,$latmax $indir/$infile $outdir/$outfile

    echo The current year-month is: $yy $mm2d
    let yy=yy+1 

  done #yy

  # Merge nc files
  outfile_all=${ivar}_${experiment}_${freq}_*${FIRST_MONTH}${FIRST_DAYHHMM}'-'*${LAST_MONTH}${LAST_DAYHHMM}'_smalldomain.nc'
  outfile_merge=${ivar}_${experiment}_${freq}_${FIRST_YEAR}${FIRST_MONTH}${FIRST_DAYHHMM}'-'${LAST_YEAR}${LAST_MONTH}${LAST_DAYHHMM}'.nc'
  outfile_merge_cmorized=${ivar}_${experiment_cmorized}_${freq}_${FIRST_YEAR}${FIRST_MONTH}${FIRST_DAYHHMM}'-'${LAST_YEAR}${LAST_MONTH}${LAST_DAYHHMM}'.nc'
  if [ -f $outdir/$outfile_merge ]; then
    rm  $outdir/$outfile_merge
  fi
  cdo mergetime $outdir/$outfile_all $outdir/$outfile_merge 
  rm $outdir/$outfile_all
  mv $outdir/$outfile_merge  $outdir/$outfile_merge_cmorized

done #ivar

