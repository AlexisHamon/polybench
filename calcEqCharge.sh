#!/bin/bash

# Chemin vers le fichier C à modifier
fichier_c=$1

# Les lignes de codes à ajouter
Include='#include <stdio.h>\n\
#include <sys/time.h>\n\
#include "rtclock.h"\
#include <stdlib.h>\n'

InitVar='\
/* Initialization temporal variables */\
double t_start;\n\
/* récupération du nombre de threads, avant la section omp parallel.\
 Avant la première exécution du programme, il faut renseigner la variable\
 d'\''environnement : export OMP_NUM_THREADS=X, où X est le nombre de threads */\
const int _ThreadCount = atoi(getenv("OMP_NUM_THREADS")); \
double _time_threads[_ThreadCount];\n\
/* initialisation du tableau des mesures à 0, afin de pouvoir cumuler */\
for (int _i=0; _i<_ThreadCount; _i++) _time_threads[_i]=0.0; \
/* temps d'\''exécution totale */\
double tall_start=rtclock();\n'

premierappelclock='\
/* Premier appel à la fonction rtclock */\
t_start = rtclock();\n'

ompparallel='/* Premier appel à la fonction rtclock */\
t_start = rtclock();\
/*On ajoute la clause "shared(_time_threads) firstprivate(t_start)" et le nowait*/\
#pragma omp parallel shared(_time_threads) firstprivate(t_start)\
{\n'

collectiontemp='/*Collecte des temps de chaque thread */\
_time_threads[omp_get_thread_num()] += rtclock() - t_start;\n}'

affichage='/* Affichage des temps d'\''exécution */\
for(int i=0;i<_ThreadCount;i++){\
printf("%0.6lf \\n", _time_threads[i]);\
}\n'

affichage2='/* Il n'\''y a plus de boucles paralleles, on peut afficher et traiter les résultats du tableau _time_threads */\
 /* Mathis : exemple d'\''affichage (à revoir) : */ \
double _AVERAGE=0, _MIN=999, _MAX=0, _ECART_TYPE=0,_G1=0,_G2=0; \
tall_start=rtclock()-tall_start; \
/*On affiche le temps de chaque thread*/ \
for(int i=0;i<_ThreadCount;i++){ \
  printf(\"Time thread no. %d: %0.6lfs\\n\", i, _time_threads[i]); \
} \
 \
 \
for (int _NoThread=0; _NoThread<_ThreadCount; _NoThread++) { \
  //printf(\"Time thread no. %d: %0.6lfs\\n\", _NoThread, _time_threads[_NoThread]); \
  if (_MIN>_time_threads[_NoThread]) _MIN=_time_threads[_NoThread]; \
  if (_MAX<_time_threads[_NoThread]) _MAX=_time_threads[_NoThread]; \
  _AVERAGE+=_time_threads[_NoThread]; \
} \
 \
printf(\"Average time = %0.6lfs - Max time = %0.6lfs - Min time = %0.6lfs - Min-Max distance = %0.2f%%\\n\",_AVERAGE/_ThreadCount,_MAX, _MIN, (_MAX - _MIN)*100/_MAX); \
/* \
La métrique de déséquilibre en pourcentage λ =(Lmax/Lavg-1)×100% est utilisée pour mesurer le déséquilibre de l'\''exécution parallèle, \
Plus la valeur de λ est faible, meilleur est l'\''équilibre de charge. \
 \
*/ \
  printf(\"Imbalance metric λ = %0.6f%%\\n\", (_MAX/(_AVERAGE/_ThreadCount)-1)*100); \
 \
  /* \
  Ecart-type  \
  */ \
  for (int _NoThread=0; _NoThread<_ThreadCount; _NoThread++) { \
    _ECART_TYPE+=pow(_time_threads[_NoThread]-_AVERAGE/_ThreadCount,2); \
  } \
  _ECART_TYPE=sqrt(_ECART_TYPE/_ThreadCount); \
  printf(\"Standart deviation σ = %0.6lf\\n\",_ECART_TYPE); \
 \
  /* \
  skew-ness g1 and kurtosis g2\
  g1 = E[((x-μ)/σ)^3]\
  g2 = E[((x-μ)/σ)^4]-3\
  more g1 is near 0, more the distribution is symetric \
  more g2 is near 0, more the distribution is \"peaked\" \
  \
  */ \
  for (int _NoThread=0; _NoThread<_ThreadCount; _NoThread++) { \
    _G1+=pow((_time_threads[_NoThread]-_AVERAGE/_ThreadCount)/_ECART_TYPE,3); \
    _G2+=pow((_time_threads[_NoThread]-_AVERAGE/_ThreadCount)/_ECART_TYPE,4); \
  } \
  _G1=_G1/_ThreadCount; \
  _G2=_G2/_ThreadCount; \
  _G2=_G2-3; \
  printf(\"Skew-ness g1 = %0.6lf\\n\",_G1); \
  printf(\"Kurtosis g2 = %0.6lf\\n\",_G2); \
  printf(\"Total time = %0.6lfs\\n\",tall_start); \
'


# Vérification si le fichier C existe
if [ -f "$fichier_c" ]; then
  # On ajoute l'include après register int lbv, ubv;
    sed -i '/^#include <omp.h>/a\
'"$Include" "$fichier_c"

  # On ajoute l'initialisation des variables temporelles 
  # après register int lbv, ubv;
    sed -i '/register int lbv, ubv;/a\
'"$InitVar" "$fichier_c"



  # On ajoute les clauses "shared(_time_threads) firstprivate(t_start)"
  # avant la ligne #pragma omp parallel for 
    sed -i '/#pragma omp parallel for/i\
'"$ompparallel" "$fichier_c"


  #On remplace #pragma omp parallel for ... par #pragma omp for ...
    sed -i 's/#pragma omp parallel for/#pragma omp for/g' "$fichier_c"

  #On ajoute nowait à la fin de la ligne #pragma omp for ...
    sed -i 's/#pragma omp for/#pragma omp for nowait/g' "$fichier_c"
    
  #On collecte les temps à la fin de la section parallèle 
  #quand on attend la parenthèse fermante de la boucle for
  accolade_count=0
  start_read=false
  numligne=0
  #on commence le read après la ligne #pragma omp parallel for
  while read -r line
  do
    numligne=$((numligne+1))

    if [[ $line == *"#pragma omp parallel"* ]]; then
      start_read=true
    fi
    if [[ $start_read = false ]]; then
      continue
    fi 

    if [[ $line == *"{"* ]]; then

      accolade_count=$((accolade_count+1))

    fi
    if [[ $line == *"}"* ]]; then
      accolade_count=$((accolade_count-1))

    fi

    if [[ $accolade_count -eq 1 ]] && [[ $line == *"}"* ]]; then
      #on ajoute les lignes de collecte des temps
      sed -i "$numligne a\\$collectiontemp" "$fichier_c"
      start_read=false
      accolade_count=0
      numligne=$((numligne+3))
    fi
  done < "$fichier_c"

  #on affiche les temps à la fin de la fonctio static void kernel_...
  accolade_count=0
  start_read=false
  numligne=0
  while read -r line
  do
    numligne=$((numligne+1))
    if [[ $line == *"void kernel_"* ]]; then
      start_read=true
    fi

    if [[ $start_read = false ]]; then
      continue
    fi
    if [[ $line == *"{"* ]]; then
      accolade_count=$((accolade_count+1))

    fi  

    if [[ $line == *"}"* ]]; then
      accolade_count=$((accolade_count-1))

    fi

    if [[ $accolade_count -eq 0 ]] && [[ $line == *"}"* ]]; then
      #on ajoute le code pour afficher les temps et les métriques
      numligne=$((numligne-1))

      sed -i "$numligne a\\$affichage" "$fichier_c"
      start_read=false
      numligne=$((numligne+3))
    fi

  done < "$fichier_c"
  
  echo "Modification du fichier C effectuée avec succès."
else
  echo "Le fichier C spécifié n'existe pas."
fi
