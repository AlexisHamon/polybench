#!/bin/bash

# Fonction pour générer le contenu LaTeX à partir des données
# generate_tex_content "2mm" "2mm.c" "$coord_tile" "$coord_algebraic_tile" "$g1" "$g2" "$std_dev" "$pim" "$ag1" "$ag2" "$astd_dev" "$apim" 

generate_tex_content() {
  local file_name=$1
  local task_name=$2
  local tile_data=$3
  local algebraic_tile_data=$4
  local g1_tile=$5
  local g2_tile=$6
  local std_dev_tile=$7
  local pim_tile=$8
    local g1_atile=$9
  local g2_atile=${10}
  local std_dev_atile=${11}
    local pim_atile=${12}
    echo "g1_tile=$g1_tile"
    echo "g2_tile=$g2_tile"
    echo "std_dev_tile=$std_dev_tile"
    echo "pim_tile=$pim_tile"
    echo "g1_atile=$g1_atile"
    echo "g2_atile=$g2_atile"
    echo "std_dev_atile=$std_dev_atile"
    echo "pim_atile=$pim_atile"


  cat > "stat.tex" <<EOF
\documentclass{article}
\usepackage{pgfplots}

\begin{document}

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
    \addlegendentry{ALGEBRIC TILE}

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
    \hline
  \end{tabular}
\end{table}

\end{document}
EOF
}

# Lecture des données à partir de l'entrée standard
read -r -d '' data_string
file_name=$(grep -B 1 "##TILE" <<< "$data_string" | head -n 2)
echo "file_name=$file_name"
data_string="${data_string%"${data_string##*[![:space:]]}"}"  # Supprime les espaces en fin de chaîne
#on remplace les \n par des espaces
data_string="${data_string//$'\n'/ }"
#on récupère le nom du fichier juste avant ##TILE on cherche les lettres avant


# Extraction des données TILE
tile_data=$(grep -oP '(?<=##TILE\s\s)[[0-9.\s]*(\s)*]*' <<< "$data_string")
echo "tile :$tile_data"
# Extraction des données ALGEBRIC TILE
algebraic_tile_data=$(grep -oP '(?<=##ALGEBRIC TILE\s\s)[[0-9.\s]*(\s)*]*' <<< "$data_string")
echo "algebraic tile :$algebraic_tile_data"


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
# Fonction pour calculer l'écart type
calculate_std_dev() {
  local data=("$@")
  local sum=0
  local sum_sq=0
  local count=${#data[@]}

  for value in "${data[@]}"; do
    sum=$(bc <<< "$sum + $value")
    sum_sq=$(bc <<< "$sum_sq + ($value * $value)")
  done

  local mean=$(bc <<< "scale=10; $sum / $count")
  local variance=$(bc <<< "scale=10; ($sum_sq / $count) - ($mean * $mean)")
  local std_dev=$(bc <<< "scale=5; sqrt($variance)")

  echo "$std_dev"
}

# Fonction pour calculer le skewness (g1)
calculate_g1() {
  local data=("$@")
  local count=${#data[@]}
  local std_dev=$(calculate_std_dev "${data[@]}")
  local sum=0

  # Calcul de la moyenne
  local mean=0
  for value in "${data[@]}"; do
    mean=$(bc <<< "$mean + $value")
  done
  mean=$(bc <<< "scale=10; $mean / $count")

  # Calcul de g1
  for value in "${data[@]}"; do
    sum=$(bc <<< "$sum + (($value - $mean) * ($value - $mean) * ($value - $mean))")
  done

  local g1=$(bc <<< "scale=5; ($sum / ($count * $std_dev * $std_dev * $std_dev))")

  echo "$g1"
}

# Fonction pour calculer le kurtosis (g2)
calculate_g2() {
  local data=("$@")
  local count=${#data[@]}
  local std_dev=$(calculate_std_dev "${data[@]}")
  local sum=0

  # Calcul de la moyenne
  local mean=0
  for value in "${data[@]}"; do
    mean=$(bc <<< "$mean + $value")
  done
  mean=$(bc <<< "scale=10; $mean / $count")

  # Calcul de g2
  for value in "${data[@]}"; do
    sum=$(bc <<< "$sum + (($value - $mean) * ($value - $mean) * ($value - $mean) * ($value - $mean))")
  done

  local g2=$(bc <<< "scale=5; (($count * $sum) / ($std_dev * $std_dev * $std_dev * $std_dev)) - 3")

  echo "$g2"
}

# Fonction pour calculer le Percent Imbalance Metric (PIM)
calculate_pim() {
  local data=("$@")
  local count=${#data[@]}
  local max=$(printf '%s\n' "${data[@]}" | sort -rn | head -n1)
  local min=$(printf '%s\n' "${data[@]}" | sort -n | head -n1)
  local pim=$(bc <<< "scale=5; ($max - $min) / (($max + $min) / 2) * 100")

  echo "$pim"
}

# Séparation des valeurs en un tableau
IFS=' ' read -ra tile_data <<< "$tile_data"

# Calcul des statistiques
std_dev=$(calculate_std_dev "${tile_data[@]}")
g1=$(calculate_g1 "${tile_data[@]}")
g2=$(calculate_g2 "${tile_data[@]}")
pim=$(calculate_pim "${tile_data[@]}")

# Séparation des valeurs en un tableau
IFS=' ' read -ra algebraic_tile_data <<< "$algebraic_tile_data"

# Calcul des statistiques
astd_dev=$(calculate_std_dev "${algebraic_tile_data[@]}")
ag1=$(calculate_g1 "${algebraic_tile_data[@]}")
ag2=$(calculate_g2 "${algebraic_tile_data[@]}")
apim=$(calculate_pim "${algebraic_tile_data[@]}")

# Affichage des statistiques
echo "Écart type : $astd_dev"
echo "Skewness (g1) : $ag1"
echo "Kurtosis (g2) : $ag2"
echo "Percent Imbalance Metric (PIM) : $apim"

# Génération du fichier TeX
generate_tex_content "2mm" "2mm.c" "$coord_tile" "$coord_algebraic_tile" "$g1" "$g2" "$std_dev" "$pim" "$ag1" "$ag2" "$astd_dev" "$apim" 
