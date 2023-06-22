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
  local g1_tile=$5
  local g2_tile=$6
  local std_dev_tile=$7
  local pim_tile=$8
  local exec_time_tile=$9
    local g1_atile=${10}
  local g2_atile=${11}
  local std_dev_atile=${12}
    local pim_atile=${13}
  local exec_time_atile=${14}

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
      legend pos=north west
    ]

    % Données pour $task_name
    \addplot[color=blue, fill=blue] coordinates {
      $tile_data
    };
    \addlegendentry{TILE}

    \addplot[color=red, fill=red] coordinates {
      $algebraic_tile_data
    };
    \addlegendentry{ALGEBRAIC TILE}

    \end{axis}
  \end{tikzpicture}
  \caption{Temps d'exécution des threads pour le fichier $task_name}
  \label{fig:$task_name}
\end{figure}

\begin{table}[htbp]
  \centering
  \caption{Statistiques pour le fichier $task_name}
  \begin{tabular}{|c|c|c|}
    \hline
    Statistique & Algebraic Tile & Tile \\\ 
    \hline
    Skewness (g1) & $g1_atile & $g1_tile \\\ 
    Kurtosis (g2) & $g2_atile & $g2_tile \\\ 
    Écart type & $std_dev_tile & $std_dev_tile \\\ 
    Percent Imbalance metric en \% & $pim_atile & $pim_tile \\\ 
    Temps d'exécution (s) & $exec_time_atile & $exec_time_tile \\\ 
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

count=$(grep -c '#TILE' <<< "$data_string")
echo "count=$count"
init_tex 
for ((j=0; j<count; j++)); do
    i=$((j+1))
    # Lecture des données à partir de l'entrée standard
    r=$((2*i-1))

    file_name=$(grep -B 1 '##TILE' <<< $data_string| grep -v '##TILE' | sed -n "$r p")
    #on enlève les # dans le nom du fichier
    file_name="${file_name//#/}"

    # Extraction des données TILE
    tile_data=$(grep -oP -m $i '(?<=##TILE\s\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$i p")
    # echo "tile :$tile_data"
    # Extraction des données ALGEBRIC TILE
    algebraic_tile_data=$(grep -oP -m $i '(?<=##ALGEBRAIC TILE\s\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$i p")
    # echo "algebraic tile :$algebraic_tile_data"
    #Extraction du temps d'exécution
    execution_time_tile=$(grep -oP -m $i '(?<=##Execution time\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$r p")
    rank=$((r+1))
    execution_time_atile=$(grep -oP -m $i '(?<=##Execution time\s)[[0-9.\s]*(\s)*]*' <<< "$np_data_string" | sed -n "$rank p")
    # echo "execution time :$execution_time_tile et $execution_time_atile"

    # On transforme les données en coordonnées pour TikZ
    coordinates=()
    index=0

    for value in $tile_data; do
        coordinates+=("($index,$value)")
        ((index++))
    done

    coord_tile=$(IFS=' ' ; echo "${coordinates[*]}")

    coordinates=()
    index=0

    for value in $algebraic_tile_data; do
        coordinates+=("($index,$value)")
        ((index++))
    done

    coord_algebraic_tile=$(IFS=' ' ; echo "${coordinates[*]}")


    # Calcul des statistiques
    std_dev=$(calculate_ecart_type "${tile_data[@]}")
    g1=$(calculate_g1 "${tile_data[@]}")
    g2=$(calculate_g2 "${tile_data[@]}")
    max=$(calculate_max "${tile_data[@]}")
    avg=$(calculate_avg "${tile_data[@]}")
    pim=$(calculate_pim "${max[@]}" "${avg[@]}")


    # Calcul des statistiques algebraic
    astd_dev=$(calculate_ecart_type "${algebraic_tile_data[@]}")
    ag1=$(calculate_g1 "${algebraic_tile_data[@]}")
    ag2=$(calculate_g2 "${algebraic_tile_data[@]}")
    amax=$(calculate_max "${algebraic_tile_data[@]}")
    aavg=$(calculate_avg "${algebraic_tile_data[@]}")
    apim=$(calculate_pim "${max[@]}" "${avg[@]}")

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
  generate_tex_content "$file_name" "$file_name" "$coord_tile" "$coord_algebraic_tile" "$g1" "$g2" "$std_dev" "$pim" "$execution_time_tile" "$ag1" "$ag2" "$astd_dev" "$apim" "$execution_time_atile" 
  

done 

end_tex