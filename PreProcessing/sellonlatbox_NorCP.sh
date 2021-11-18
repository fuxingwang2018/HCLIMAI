#!/bin/bash

#SBATCH -N 1
#SBATCH -t 3:00:00
#SBATCH -J Sel12km
#SBATCH -e slurm_error.txt
#SBATCH -o slurm_output.txt

EXP='NorCP12'
FIRST_YEAR=1986 # 1985 available, but one-year spinup
LAST_YEAR=2005 # 2005 available
FIRST_MONTH=01
LAST_MONTH=12

if [[ "$EXP" == "NorCP12" ]]; then
    indir0='/nobackup/rossby24/proj/rossby/joint_exp/norcp/netcdf/NorCP_ALADIN_ECE_1985_2005/'
    experiment='NEU-12_ICHEC-EC-EARTH_historical_r12i1p1_HCLIMcom-HCLIM38-ALADIN_v1'
    experiment_cmorized='12km'
    freq_in='6hr' #1hr for tas, pr; 3hr for ta500..1000, hus500..1000, ua500..1000, va500..1000; 6hr for zg500..1000
    freq_out='6hr' # 3hr, 6hr
    #VAR_LIST=('pr' ) # pr, tas
    #VAR_LIST=('ta500' 'ta700' 'ta850' 'ta1000' \
    #	'hus500' 'hus700' 'hus850' 'hus1000' \
    #	'ua500' 'ua700' 'ua850' 'ua1000' \
    #	'va500' 'va700' 'va850' 'va1000' )
    VAR_LIST=('zg500' 'zg700' 'zg850' 'zg1000')

elif [[ "$EXP" == "NorCP3" ]]; then 
    indir0='/nobackup/rossby24/proj/rossby/joint_exp/norcp/netcdf/NorCP_AROME_ECE_ALADIN_1985_2005/'
    experiment='NEU-3_ICHEC-EC-EARTH_historical_r12i1p1_HCLIMcom-HCLIM38-AROME_x2yn2v1' 
    experiment_cmorized='3km'
    freq_in='1hr'
    freq_out='3hr' # 3hr, 6hr
    VAR_LIST=('pr')  # tas, pr
fi

SELMONTH=7
NAMEMONTH='July'

#17*24 grids for 12km domain, 71*93 grids for 3km domain.
lonmin='13.0'
lonmax='16.3'
latmin='57.1'
latmax='59.5'
#lonmin='13'
#lonmax='16'
#latmin='56.5'
#latmax='58.5'

OUT_PATH='/nobackup/rossby26/users/sm_fuxwa/AI/NorCP/'
# DAYHHMM
if [[ "$freq_in" == "3hr" ]]; then
    FIRST_DAYHHMM_IN=010000 # 3hr
    LAST_DAYHHMM_IN=312100  # 3hr
elif [[ "$freq_in" == "6hr" ]]; then
    FIRST_DAYHHMM_IN=010000 # 6hr
    LAST_DAYHHMM_IN=311800  # 6hr
elif [[ "$freq_in" == "1hr" ]]; then
    if [[ " ${VAR_LIST[*]} " == *" tas "* ]]; then
        FIRST_DAYHHMM_IN=010000 # tas
        LAST_DAYHHMM_IN=312300  # tas
    elif [[ " ${VAR_LIST[*]} " == *" pr "* ]]; then
        FIRST_DAYHHMM_IN=010030 # pr
        LAST_DAYHHMM_IN=312330  # pr
    fi
fi

if [[ "$freq_out" == "3hr" ]]; then
    if [[ " ${VAR_LIST[*]} " == *" pr "* ]]; then
        FIRST_DAYHHMM_OUT=010130 # 3hr
        LAST_DAYHHMM_OUT=312230  # 3hr
    else
        FIRST_DAYHHMM_OUT=010000 # 3hr
        LAST_DAYHHMM_OUT=312100  # 3hr
    fi
elif [[ "$freq_out" == "6hr" ]]; then
    if [[ " ${VAR_LIST[*]} " == *" pr "* ]]; then
        FIRST_DAYHHMM_OUT=010300 # 6hr
        LAST_DAYHHMM_OUT=312100  # 6hr
    else
        FIRST_DAYHHMM_OUT=010000 # 6hr
        LAST_DAYHHMM_OUT=311800  # 6hr
    fi
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

    echo 'processing' ${ivar}

    indir=${indir0}/${freq_in}/${ivar}
    outdir=${OUT_PATH}${experiment_cmorized}/${freq_out}/${ivar}
    if [ ! -e ${outdir} ] ; then
        mkdir -p ${outdir}
    fi
    infile=${ivar}_${experiment}_${freq_in}_${yy}${FIRST_MONTH}${FIRST_DAYHHMM_IN}'-'${yy}${LAST_MONTH}${LAST_DAYHHMM_IN}'.nc' 
    outfile_smalldomain=${ivar}_${experiment}_${freq_in}_${yy}${FIRST_MONTH}${FIRST_DAYHHMM_IN}'-'${yy}${LAST_MONTH}${LAST_DAYHHMM_IN}'_smalldomain.nc'
    outfile_newfreq=${ivar}_${experiment}_${freq_out}_${yy}${FIRST_MONTH}${FIRST_DAYHHMM_OUT}'-'${yy}${LAST_MONTH}${LAST_DAYHHMM_OUT}'_smalldomain.nc'

    cdo sellonlatbox,$lonmin,$lonmax,$latmin,$latmax $indir/$infile $outdir/$outfile_smalldomain

    if [[ "$freq_in" == "1hr" ]] && [[ "$freq_out" == "3hr" ]] ; then
        if [[ " ${VAR_LIST[*]} " == *" pr "* ]]; then
            cdo timselmean,3 $outdir/$outfile_smalldomain $outdir/$outfile_newfreq
        else
            #cdo select,timestep=$(seq 1 3 8808 | shuf | tr '\n' ',' | sed '$s/,$/\n/') tas_12km_1hr_200001010000-200912312300.nc tas_12km_3hr_200001010000-200912312300.nc
            cdo select,timestep=$(seq 1 3 8808 | tr '\n' ',' | sed '$s/,$/\n/') $outdir/$outfile_smalldomain $outdir/$outfile_newfreq
        fi
    elif [[ "$freq_in" == "1hr" ]] && [[ "$freq_out" == "6hr" ]] ; then
        if [[ " ${VAR_LIST[*]} " == *" pr "* ]]; then
            cdo timselmean,6 $outdir/$outfile_smalldomain $outdir/$outfile_newfreq
        else
            cdo select,timestep=$(seq 1 6 8808 | tr '\n' ',' | sed '$s/,$/\n/') $outdir/$outfile_smalldomain $outdir/$outfile_newfreq
        fi
    elif [[ "$freq_in" == "3hr" ]] && [[ "$freq_out" == "6hr" ]] ; then
        if [[ " ${VAR_LIST[*]} " == *" pr "* ]]; then
            cdo timselmean,2 $outdir/$outfile_smalldomain $outdir/$outfile_newfreq
        else
            cdo select,timestep=$(seq 1 2 3000 | tr '\n' ',' | sed '$s/,$/\n/') $outdir/$outfile_smalldomain $outdir/$outfile_newfreq
        fi
    fi

    echo The current year-month is: $yy $mm2d
    let yy=yy+1 
  done #yy

  # Merge nc files
  outfile_all=${ivar}_${experiment}_${freq_out}_*${FIRST_MONTH}${FIRST_DAYHHMM_OUT}'-'*${LAST_MONTH}${LAST_DAYHHMM_OUT}'_smalldomain.nc'
  outfile_merge=${ivar}_${experiment}_${freq_out}_${FIRST_YEAR}${FIRST_MONTH}${FIRST_DAYHHMM_OUT}'-'${LAST_YEAR}${LAST_MONTH}${LAST_DAYHHMM_OUT}'.nc'
  outfile_merge_cmorized=${ivar}_${experiment_cmorized}_${freq_out}_${FIRST_YEAR}${FIRST_MONTH}${FIRST_DAYHHMM_OUT}'-'${LAST_YEAR}${LAST_MONTH}${LAST_DAYHHMM_OUT}'.nc'
  outfile_month=${ivar}_${experiment_cmorized}_${freq_out}_${NAMEMONTH}_${FIRST_YEAR}${FIRST_MONTH}${FIRST_DAYHHMM_OUT}'-'${LAST_YEAR}${LAST_MONTH}${LAST_DAYHHMM_OUT}'.nc'
  if [ -f $outdir/$outfile_merge ]; then
    rm  $outdir/$outfile_merge
  fi
  cdo mergetime $outdir/$outfile_all $outdir/$outfile_merge 
  rm $outdir/$outfile_all 
  rm $outdir/${ivar}_${experiment}_${freq_in}_*${FIRST_MONTH}${FIRST_DAYHHMM_IN}'-'*${LAST_MONTH}${LAST_DAYHHMM_IN}'_smalldomain.nc'
  mv $outdir/$outfile_merge  $outdir/$outfile_merge_cmorized
  cdo selmon,${SELMONTH} $outdir/$outfile_merge_cmorized $outdir/$outfile_month

done #ivar

