#!/bin/bash
################################################################################
#
# REFERENCE            :
#
# ROLE                 : Affiche sur la SS le nombre de dossiers, de fichiers + la taille en ko + detection de crtl m
#
# SYNTAXE              : nbre [repertoire]
#
# EXEMPLES - TESTS OK  : nbre
#
# EXEMPLES - TESTS NOK : nbre rep1 rep2
#
# PARAMETRES           : [repertoire] repertoire a analyser
#
# DONNEES RETOURNEES   : Affiche a l'ecran le resultat
#
# DONNEES ACCEDEES     : fichier et sous repertoires
#
# PROCEDURES APPELLEES : 
#
# REMARQUES            :
#
#
# HISTORIQUE :
#
#  Date                  Auteur            Type de mise a jour
#  31/AOUT/98            Andre GADANHO     Mise aux normes des outils
#
# VERSION : 11/05/2007 : : Sylvain GAUNET
# DM-ID : 1443 : 11/05/2007    : Prise en compte de la DM 1443
# VERSION : 05/09/2008 : : Sylvain GAUNET
# DM-ID : 1870 : 05/09/2008    : Prise en compte de la DM 1870
# FA-ID : 1856 : 05/09/2008    : Prise en compte de la DM 1856
# VERSION:1.14_linux:DM:1893:07/11/2008:Sortie du nbre plus consise
# VERSION: 1.16 : DM-ID : 1961 : 14/01/2009 : Mettre àour les versions ctrlnok et nbre sur HP
# VERSION: 1.17 : DM-ID : 3085 : 23/12/2014 : Ajout de tests de fichiers lourds pour LargeFile
# VERSION : 2.5 : DM : 3085  : 10/12/2015 : Test du type de machine
# VERSION : 2.7 : DM : 3465  : 07/07/2017 : Supression des commandes "echo" laissees lors du developpement de la version precedente
# VERSION : 2.7 : DM : 3472  : 07/07/2017 : correction de l'affichage de tailles de fichiers
# VERSION : 2.7 : DM : 3522  : 07/07/2017 : Outils SGC : nbre (message incomplet)  
# VERSION : 2.12 : DM : 3084 : 09/09/2019 : Outils SGC : Ajout du nouveau controle sur les crtl+M
# VERSION : 2.12 : DM : 3683 : 09/09/2019 : Gerer la sortie des outils sur interruptions
# VERSION : 2.12 : DM : 3778 : 09/09/2019 : Gerer la sortie des outils sur interruptions
# FIN-HISTORIQUE
#
################################################################################

############################################################
# Declaration des variables globales
############################################################
rougefonce='\e[0;31m'
vertclair='\e[1;32m'
vertfonce='\e[0;32m'
blanc='\e[1;37m'
gestion_affichage=0
ctrlc=1
############################################################
# Gestion des interruptions
############################################################
function interrupt()
{	
        ctrlc=0
	kill -HUP "${GLB_PID_BG}"
	return ${ctrlc}
}

trap interrupt SIGINT

function clean_up()
{
        \rm -rf ${GLB_RTMP}
	exit 1 
}

trap clean_up SIGHUP SIGTERM EXIT 

function log()
{
	echo -e "Une erreur s'est produite durant le déulement du script. Veuillez contacter l'administrateur"
	exit 1
}

#trap log ERR

############################################################
# Initialisations des espaces temporaires
############################################################
# Initialisations des espaces temporaires
if [ "_${SGC_REP_TMP}" == "_" ]
then
  #Par defaut on utilise /tmp
  GLB_RTMP=/tmp/nbrectrlm$$
mkdir ${GLB_RTMP} 2>/dev/null; rc=$?
    [ ${rc} -ne 0 ] && \
    echo "La creation du dossier temporaire a echoue." && \
    exit 1
else
  # Si la variable de definition de l'espace temporaire existe : on l'utilise

    GLB_RTMP=${SGC_REP_TMP}/nbrectrlm$$
    mkdir ${GLB_RTMP} 2>/dev/null; rc=$?
    [ ${rc} -ne 0 ] && \
    echo "La creation du dossier temporaire a echoue." && \
    exit 1
fi


############################################################
# Envoi message usage sur la console
############################################################
#
Usage()
{
echo ""
echo "Usage: nbre [repert]"
echo ""
echo -e "\t[repert] repertoire a analyser sinon le repertoire courant est analyse"
echo -e "\t[-h] Affiche cette aide en ligne"
#echo -e "\t[--version] Obtenir le numero de version de l'outil"
echo -e "\tCette outil permet de calculer le nombre de repertoire, le nombre de fichier ainsi que la taille, egalement de realiser le controle sur les caracteres ctrl+M"
#which_outil=$(which nbre)
#version=$(dirname ${which_outil})
#version=${version}/outils_sgc/ddc/ddc.txt
#version=$(grep -i -m1 version ${version} | awk -F: '{print $NF}')	
#echo ""
#echo "Information de OUTILS_SGC en production: "
#echo -e "\tVersion: "${version}
exit 1
}

#############################################################
if [ "$1" = "-h" ] 
then
  Usage
fi

#if [ "$1" = "--version" ]
#then
# 	which_outil=$(which nbre)
#        version=$(dirname ${which_outil})
#        version=${version}/outils_sgc/ddc/ddc.txt
#        version=$(grep -i -m1 version ${version} | awk -F: '{print $NF}')
#        echo ${version}
# exit 1
#fi

if [ "$#" -gt "1" ] 
then
  Usage
fi

if [ "$1" != "" ]
then
   REP="$1"
else
   REP="."
fi

if [ ! -d "$REP" ]
then
	echo "Repertoire $REP non trouve."
	exit 1
fi

echo "---------- Debut Traitement ----------"
echo "---------- Debut nbre ----------"
echo "Analyse de $REP"

nbrep=$(find "$REP" -type d -print | wc -l)
nbfich=$(find "$REP" -type f -print | wc -l)
taille=$(du -sk "$REP" | awk '{ print $1 }')

echo "$nbfich fichiers, $nbrep repertoires, $taille Ko"
TAILLE_MAX="200000"
echo "---------- Fin nbre ----------"

echo ""
echo "---------- Resultat Controle M ----------"
#find . -type f -print0 | xargs -0 file | grep CRLF > ${GLB_RTMP}/ctrlM.res &
find . -type f > ${GLB_RTMP}/fichier_ac_ctrlM.res &
GLB_PID_BG=$!
wait ${GLB_PID_BG}
while read ligne 
do
file "${ligne}" 
done < ${GLB_RTMP}/fichier_ac_ctrlM.res > ${GLB_RTMP}/fichier_ac_ctrlM1.res &
GLB_PID_BG=$!
wait ${GLB_PID_BG}
grep CRLF ${GLB_RTMP}/fichier_ac_ctrlM1.res > ${GLB_RTMP}/ctrlM.res &
GLB_PID_BG=$!
wait ${GLB_PID_BG}
grep CRLF ${GLB_RTMP}/fichier_ac_ctrlM1.res > ${GLB_RTMP}/ctrlM.res
if [ -s ${GLB_RTMP}/ctrlM.res ]; then
  cat ${GLB_RTMP}/ctrlM.res 
  gestion_affichage=1
else
  gestion_affichage=2
fi
\rm -rf ${GLB_RTMP}/ctrlM.res
if [ ${ctrlc} -eq 0 ];
  then
    echo ""
    echo -e "${rougefonce}Attention vous avez interrompu le script${blanc}"

fi  
if [ ${gestion_affichage} -eq 1 ];
  then
    echo ""  
    echo -e "Controle des crtl+M :${rougefonce}NOK. Attention, la livraison comporte des ^M, une relivraison est a demande sauf si les ctrl M sont justifies (ex: envrionnement Windows...)${blanc}"
fi
if [ ${gestion_affichage} -eq 2 ];
then
        echo -e "Controle des ctrl+M : ${vertclair}OK.${blanc}"
fi
#echo "---------- Fin Controle M ----------"



