#!/bin/bash

# Fonction pour générer le contenu LaTeX à partir des données
# generate_tex_content "2mm" "2mm.c" "$coord_tile" "$coord_algebraic_tile" "$g1" "$g2" "$std_dev" "$pim" "$ag1" "$ag2" "$astd_dev" "$apim" 

init_tex() {
  cat > "stat.tex" <<EOF
   \documentclass{article}
\usepackage{pgfplots}
\begin{document}
EOF
}

end_tex() {
  cat >> "stat.tex" <<EOF
  \end{document}
EOF
}

generate_tex_content() {
  local file_name=$1
  local task_name=$2
  local tile_data=$3
  local algebraic_tile_data=$4
  local tile_data_dynamic=$5
  local g1_tile=$6
  local g2_tile=$7
  local std_dev_tile=$8
  local pim_tile=$9
  local exec_time_tile=${10}
    local g1_atile=${11}
  local g2_atile=${12}
  local std_dev_atile=${13}
    local pim_atile=${14}
  local exec_time_atile=${15}
  local g1_tile_dynamic=${16}
  local g2_tile_dynamic=${17}
  local std_dev_tile_dynamic=${18}
  local pim_tile_dynamic=${19}
  local exec_time_tile_dynamic=${20}

  echo "exec_time_tile_dynamic=$algebraic_tile_data"
    # echo "g1_tile=$g1_tile"
    # echo "g2_tile=$g2_tile"
    # echo "std_dev_tile=$std_dev_tile"
    # echo "pim_tile=$pim_tile"
    # echo "g1_atile=$g1_atile"
    # echo "g2_atile=$g2_atile"
    # echo "std_dev_atile=$std_dev_atile"
    # echo "pim_atile=$pim_atile"


  cat >> "stat.tex" <<EOF
\begin{figure}
\centering

\begin{tikzpicture}
\begin{axis}[
  ybar,
  bar width=0.5cm,
  xlabel={Thread no.},
  ylabel={Temps (s)},
  ymin=0,
  legend pos=south west,
  width=0.5\textwidth,
  xtick=data
]

% Données pour le premier graphique (à gauche)
\addplot[color=blue, fill=blue] coordinates {
  $tile_data
};
\addlegendentry{Tile (static))}

\end{axis}
\end{tikzpicture}
\hfill
\begin{tikzpicture}
\begin{axis}[
  ybar,
  bar width=0.5cm,
  xlabel={Thread no.},
  ylabel={Temps (s)},
  ymin=0,
  legend pos=south west,
  width=0.5\textwidth,
  xtick=data
]

% Données pour le deuxième graphique (au milieu)
\addplot[color=red, fill=red] coordinates {
  $tile_data_dynamic
};
\addlegendentry{Tile (dynamic)}

\end{axis}
\end{tikzpicture}
\hfill
\begin{tikzpicture}
\begin{axis}[
  ybar,
  bar width=0.5cm,
  xlabel={Thread no.},
  ylabel={Temps (s)},
  ymin=0,
  legend pos=south west,
  width=0.5\textwidth,
  xtick=data
]

% Données pour le troisième graphique (à droite)
\addplot[color=green, fill=green] coordinates {
  $algebraic_tile_data
};
\addlegendentry{Algebraic tile (static)}

\end{axis}
\end{tikzpicture}

\caption{Temps d'exécution des threads pour le fichier $task_name}
\label{fig:graphes}
\end{figure}

\begin{table}[htbp]
  \centering
  \caption{Statistiques pour le fichier $task_name}
  \begin{tabular}{|c|c|c|c|}
    \hline
    Statistique & Algebraic Tile & Tile (static) & Tile (dynamic) \\\ 
    \hline
    Skewness (g1) & $g1_atile & $g1_tile & $g1_tile_dynamic \\\ 
    Kurtosis (g2) & $g2_atile & $g2_tile & $g2_tile_dynamic \\\ 
    Écart type & $std_dev_atile & $std_dev_tile & $std_dev_tile_dynamic\\\ 
    Percent Imbalance metric en \% & $pim_atile & $pim_tile & $pim_tile_dynamic\\\ 
    Temps moyen (s) & $exec_time_atile & $exec_time_tile & $exec_time_tile_dynamic \\\ 
    \hline
  \end{tabular}
\end{table}
\newpage

EOF
}


# Calcul des métriques
# Fonctions de calcul
calculate_ecart_type() {
  local data=("$@")
  echo $data | awk 'BEGIN{FS=" "; count=0; sum=0; sq_sum=0;}
{
    for(i=1; i<=NF; i++){
        sum+=$i;
        count++;
    }
    mean=sum/count;
    for(i=1; i<=NF; i++){
        sq_sum+=($i-mean)*($i-mean);
    }
  
  }
END{
    print sqrt(sq_sum/count);
}'
}


#Calcul du max
calculate_max() {
  local data=("$@")
  echo $data | awk 'BEGIN{FS=" "; max=0;}
{
    for(i=1; i<=NF; i++){
        if($i>max){
            max=$i;
        }
    }
}
END{
    print max;
}'
}

#Calcul du min
calculate_min(){
  local data=("$@")
  echo $data | awk 'BEGIN{FS=" "; min=10000
;}
{
    for(i=1; i<=NF; i++){
        if($i<min){
            min=$i;
        }
    }
}
END{
    print min;
}'
}


#Calcul moyenne
calculate_avg(){
  local data=("$@")
  echo $data | awk 'BEGIN{FS=" "; count=0; sum=0;}
{
    for(i=1; i<=NF; i++){
        sum+=$i;
        count++;
    }
}
END{
    print sum/count;
}'
}

#Calcul skewness
calculate_g1() {
  local data=("$@")
  echo $data | awk 'BEGIN{FS=" "; count=0; sum=0; sq_sum=0; cube_sum=0; quad_sum=0;}
{
    for(i=1; i<=NF; i++){
        sum+=$i;
        count++;
    }
    mean=sum/count;
    sum=0;
    count=0;
    for(i=1; i<=NF; i++){
        sum+=$i-mean;
        sq_sum+=($i-mean)*($i-mean);
        cube_sum+=($i-mean)*($i-mean)*($i-mean);
        quad_sum+=($i-mean)*($i-mean)*($i-mean)*($i-mean);
        count++;
    }
}
END{
    variance=(sq_sum/count);
    std_dev=sqrt(variance);
    print 1/count*cube_sum/(std_dev*std_dev*std_dev);
}'
}

#Calcul kurtosis
calculate_g2() {
  local data=("$@")
  echo $data | awk 'BEGIN{FS=" "; count=0; sum=0; sq_sum=0; cube_sum=0; quad_sum=0;}
{
    for(i=1; i<=NF; i++){
        sum+=$i;
        count++;
    }
    mean=sum/count;
    sum=0;
    count=0;
    for(i=1; i<=NF; i++){
        sum+=$i-mean;
        sq_sum+=($i-mean)*($i-mean);
        cube_sum+=($i-mean)*($i-mean)*($i-mean);
        quad_sum+=($i-mean)*($i-mean)*($i-mean)*($i-mean);
        count++;
    }
}
END{
    variance=(sq_sum/count);
    std_dev=sqrt(variance);
    print 1/count*quad_sum/(std_dev*std_dev*std_dev*std_dev)-3;
}'
}


#Calcul Percent imbalance metric pim = (max/avg - 1) * 100
calculate_pim() {
  max=$1
  avg=$2
  echo $data | awk -v mean="$avg" -v max="$max" 'BEGIN{FS=" "; count=0; sum=0; sq_sum=0; cube_sum=0; quad_sum=0;}
  {
  
      }
  END{
      print (max/mean - 1) * 100;
  
  }'
}


read -r -d '' data_string
np_data_string="${data_string%"${data_string##*[![:space:]]}"}"  # Supprime les espaces en fin de chaîne
#on remplace les \n par des espaces
np_data_string="${np_data_string//$'\n'/ }"

count=$(grep -c '##ALGEBRAIC TILE ' <<< "$data_string")
echo "count=$count"
init_tex 
for ((j=0; j<count; j++)); do
    i=$((j+1))
    # Lecture des données à partir de l'entrée standard
    r=$((2*i-1))

    file_name=$(grep -B 1 '##TILE static' <<< $data_string| grep -v '##TILE' | sed -n "$r p")
    #on enlève les # dans le nom du fichier
    file_name="${file_name//#/}"

    # Extraction des données TILE
    tile_data_static=$(grep -oP -m $i '(?<=##TILE static\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$i p")
    echo "tile :$tile_data_static"
    tile_data_dynamic=$(grep -oP -m $i '(?<=##TILE dynamic\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$i p")
    echo "tile :$tile_data_dynamic"
    # echo "tile :$tile_data"
    # Extraction des données ALGEBRIC TILE
    algebraic_tile_data=$(grep -oP -m $i '(?<=##ALGEBRAIC TILE\s\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$i p")
    echo "algebraic tile :$algebraic_tile_data"
    #Extraction du temps d'exécution
    time_rank=$((3*i-2))
    execution_time_tile_static=$(grep -oP -m $i '(?<=##Execution time\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$time_rank p")
    time_rank=$((time_rank+1))
    execution_time_tile_dynamic=$(grep -oP -m $i '(?<=##Execution time\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$time_rank p")
    time_rank=$((time_rank+1))
    execution_time_atile=$(grep -oP -m $i '(?<=##Execution time\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$time_rank p")
    echo "execution time :$execution_time_tile_static et $execution_time_tile_dynamic et $execution_time_atile" 

    # On transforme les données en coordonnées pour TikZ
    coordinates=()
    index=0

    for value in $tile_data_static; do
        coordinates+=("($index,$value)")
        ((index++))
    done

    coord_tile_static=$(IFS=' ' ; echo "${coordinates[*]}")

    coordinates=()
    index=0

    for value in $tile_data_dynamic; do
        coordinates+=("($index,$value)")
        ((index++))
    done

    coord_tile_dynamic=$(IFS=' ' ; echo "${coordinates[*]}")


    coordinates=()
    index=0

    for value in $algebraic_tile_data; do
        coordinates+=("($index,$value)")
        ((index++))
    done

    coord_algebraic_tile=$(IFS=' ' ; echo "${coordinates[*]}")


    # Calcul des statistiques pavage classique (static)
    std_dev=$(calculate_ecart_type "${tile_data_static[@]}")
    g1=$(calculate_g1 "${tile_data_static[@]}")
    g2=$(calculate_g2 "${tile_data_static[@]}")
    max=$(calculate_max "${tile_data_static[@]}")
    avg=$(calculate_avg "${tile_data_static[@]}")
    pim=$(calculate_pim "${max[@]}" "${avg[@]}")

    # Calcul des statistiques pavage classique (dynamic)
    dstd_dev=$(calculate_ecart_type "${tile_data_dynamic[@]}")
    dg1=$(calculate_g1 "${tile_data_dynamic[@]}")
    dg2=$(calculate_g2 "${tile_data_dynamic[@]}")
    dmax=$(calculate_max "${tile_data_dynamic[@]}")
    davg=$(calculate_avg "${tile_data_dynamic[@]}")
    dpim=$(calculate_pim "${dmax[@]}" "${davg[@]}")
    


    # Calcul des statistiques algebraic
    astd_dev=$(calculate_ecart_type "${algebraic_tile_data[@]}")
    ag1=$(calculate_g1 "${algebraic_tile_data[@]}")
    ag2=$(calculate_g2 "${algebraic_tile_data[@]}")
    amax=$(calculate_max "${algebraic_tile_data[@]}")
    aavg=$(calculate_avg "${algebraic_tile_data[@]}")
    apim=$(calculate_pim "${amax[@]}" "${aavg[@]}")

    # Affichage des statistiques
    echo "Fichier : $file_name"
    echo "ALGEBRAIC TILE"
    echo "Écart type : $astd_dev"
    echo "Skewness (g1) : $ag1"
    echo "Kurtosis (g2) : $ag2"
    echo "Percent Imbalance Metric (PIM) : $apim"
    echo ""
    echo "TILE"
    echo "Écart type : $std_dev"
    echo "Skewness (g1) : $g1"
    echo "Kurtosis (g2) : $g2"
    echo "Percent Imbalance Metric (PIM) : $pim"
    echo ""
    echo ""


  # Génération du fichier TeX
  generate_tex_content "$file_name" "$file_name" "$coord_tile_static" "$coord_algebraic_tile" "$coord_tile_dynamic" "$g1" "$g2" "$std_dev" "$pim" "$max" "$ag1" "$ag2" "$astd_dev" "$apim" "$amax" "$dg1" "$dg2" "$dstd_dev" "$dpim" "$dmax"
  
  echo "maxs : $max et $dmax et $amax"
done 

end_tex

# Génération du fichier PDF
texi2dvi -I ./doc --pdf stat.tex -o stat.pdf --quiet