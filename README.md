# Présentation générale
 
## Utilisation et options
### Test de validité des algorithmes de répartition de charge
Pour tester de manière unitaire un fichier .c faire la commande suivante :
```
./unit_test <fichier>
```
Pour tester l'ensemble des fichiers de polybench faire la commande suivante :
```
./all_unit_tests
```
On obtient dans le terminal les résultats de la comparaison des matrices du fichier parallélisé et celui de base. 

### Calcul de l'équilibre de charge

Le programme exécute les fichiers parallélisés sur la machine TRAHRHE de 64 coeurs. Il faut donc dans le fichier unit_charge.sh mettre son mot de passe et son identifiant de connexion et cloner ce git dans un dossier eqCharge. Il est aussi possible de mettre le mot de passe de pernias@trahrhe.icube.unistra.fr. 
Ensuite après avoir compilé avec 
```
make clean
make all
```
on peut générer les temps d'exécution des threads pour un seul fichier avec la commande suivante :
```
./unit_charge <fichier>
```
On peut aussi générer les données pour les fichiers gemm.c gemver.c gesummv.c syr2k.c syrk.c trmm.c 2mm.c 3mm.c atax.c bicg.c mvt.c correlation.c et covariance.c avec la commande suivante :
```
./all_unit_charge
```
On a ainsi généré un fichier **result.csv** sur la machine TRAHRHE. On peut le copier sur notre machine avec la commande :
```
scp trahrhe.icube.unistra.fr:eqCharge/polybench/result.csv <chemin_vers_le_dossier_polybench>
```
Ensuite on peut traiter les données grâce au script generate_stat.sh. On exécute cette commande :
```
cat result.csv | ./generate_stat.sh
```
Ainsi on a généré un fichier pdf **stat.pdf** avec les histogrammes et les statistiques.
Pour calculer l'équilibre de charge en dataset DOOM il faut changer la variable TESTS en TESTSDOOM dans all_unit_charges.sh
##Métriques d'équilibre de charge
Avant de commencer à mettre en place l'automatisation des mesures il faut comprendre ce qu'est l'équilibre de charge et quelles sont les métriques pertinentes à utilisées. Ces métriques apparaissent souvent dans la littérature du thread load balancing.  
On se réfère à l'article *Quantifying the effectiveness of load balance algorithms* de Olga Pearce et T. Gamblin,.  
Cet article introduit plusieurs métriques : 
    - Percent Imbalance Metric @f$(\frac{x_{max}}{\overline{x}}-1)\times100@f$
    - Skewness, @f$g_1= \frac{\sum_{i=1}^{n} (x_i - \overline{x})^3}{n\sigma^3} @f$
    - Kurtosis, @f$g_2= \frac{\sum_{i=1}^{n} (x_i - \overline{x})^4}{n\sigma^4} @f$
    - Ecart-type @f$\sigma=\sqrt{\frac{\sum_{i=1}^{n} (x_i - \overline{x})^2}{n}}@f$  
Avec @f$x_i@f$ le temps de travail du thread @f$i@f$, @f$\overline{x}@f$ le temps moyen et @f$x_{max}@f$ le temps maximum. 



On peut interpréter la skewness comme un coefficient d'asymétrie plus le nombre est proche de zéro plus la distribution est symétrique. Le kurtosis correspond à un coefficient d'applatissement, il caractérise la proportion des queues de la distribution (les valeurs extremums). Si le kurtosis est supérieur à zéro il y a une majorité de valeurs élevées, s'il y a une majorité de valeurs faibles le kurtosis sera inférieur à zéro. L'écart-type caractérise l'écart absolue des valeurs à la moyenne.   
Le Percent Imbalance Metric indique l'écart entre la valeur maximal et la moyenne.  
J'utiliserai plutôt le coefficient de variation $ \frac{\sigma}{\overline{x}} $ que l'écart-type qui ne prend pas en compte l'ordre de grandeur des valeurs et le coefficient de Gini qui caractérise bien l'écart entre chaque valeur @f$ \frac{\sum_{i=1}^{n}\sum_{j=1}^{n} |x_i - x_j|}{2n^2\overline{x}} @f$.
##Mise en place du script d'automatisation de calcul de charges
###Repère des zones de collecte des temps
On souhaite modifier le programme parallélisé pour en sortie donner les temps de travail de chaque thread. Il faut donc repérer les section parallèle dans les programmes. 
Reprenons cet exemple : 
```
#pragma omp for schedule(static)
for ( i = 0 ; i < N ; i++ ) {
    ...
}

```
Le soucis ici est que l'on ne peut faire la collecte des temps en fin de boucle  @f$for @f$ car la synchronisation sera faite. Il faut donc modifier les sections parallèles en : 
```
#pragma omp parallel
{
#pragma omp for schedule(static) nowait
for ( i = 0 ; i < N ; i++ ) {
    ...
}
//COLLECTE DES TEMPS
}

```
Ainsi on peut récolter les temps avant la synchronisation. Il faut aussi ajouter la clause nowait pour que les threads se s'attendent pas mutuellement. 
Pour la collecte des temps on utilise un tableau de double :
```
double _time_threads[MAX_THREADS];
```
On défini aussi une fonction pour obtenir le temps  @f$rtclock() @f$
On a donc le code suivant :
```
    /* Premier appel a la fonction rtclock */
    t_start = rtclock();
    #pragma omp parallel
    {
    #pragma omp for schedule(static) nowait
    for ( i = 0 ; i < N ; i++ ) {
        ...
    }
    /*Collecte des temps de chaque thread */
    _time_threads[omp_get_thread_num()] += rtclock() - t_start;
    }
    
```
###Création du script de transformation de fichier
La modification du fichier C est faite en bash en utilisant principalement la fonction  @f$sed @f$. Par exemple cette commande remplace tous les "apple" par des "mango". 
```
    {{command}} | sed 's/apple/mango/g'
```
Par exemple avec ces instructions on ajoute  @f$shared(\_time\_threads) @f$ et  @f$firstprivate(t\_start) @f$ pour que le tableau des temps des threads soit partagé. Ensuite on change les instructions pragma omp pour pouvoir faire la collecte des temps avant la synchronisation. 
```
# On ajoute les clauses "shared(_time_threads) firstprivate(t_start)"
# avant la ligne #pragma omp parallel for 
sed -i '/#pragma omp parallel for/i\ '"$ompparallel" "$fichier_c"
    
    
#On remplace #pragma omp parallel for ... par #pragma omp for ...
sed -i 's/#pragma omp parallel for/#pragma omp for/g' "$fichier_c"
```
Pour la collecte des données on compte les accolades sous forme d'une pile à partir du  @f$omp for @f$. On dépile lorsque l'on rencontre une accolade fermante et on empile lorsque l'on a une accolade ouvrantes. Lorsque la pile est vide on ajoute la collecte des temps.
###Script global
On utilise les scripts précédents pour pouvoir effectuer la parallélisation sur ma machine puis exécuter les programmes sur la machine du laboratoire à 64 coeurs en  @f$ssh @f$. Les étapes du script  charge_unit.sh sont les suivantes :
- On va chercher les tailles donnant les meilleurs performances grâce au script  get_best.py.
- On lance la parallélisation avec  @f$polycc @f$ en classique statique et dynamique et en algébrique. 
- On applique le script de transformation  transformation.sh aux 3 fichiers.
- On compile les trois fichiers.
- On copie les exécutables sur la machine du laboratoire en ssh et on les exécute.
- On récupère les résultats en  @f$.csv @f$. 

On peut ainsi tester tous les fichiers du bench  @f$polybench @f$.
##Exploitation des données
Une fois que l'on obtient les résultats sur la machine 64 coeurs sous forme brute on les traite et on affiche les temps sous forme d'un histogramme en  @f$\LaTeX  @f$.
###Calcul des statistiques d'équilibre de charge
En sortie de chaque fichier modifié on obtient des données sous cette forme pour 4 threads :
```
#gemm.c
##TILE static 
0.029415 
0.029407 
0.029393 
0.029324 
##Execution time 
0.029572

##TILE dynamic 
0.028370 
0.010830 
0.029127 
0.029127 
##Execution time 
0.029339

##ALGEBRAIC TILE 
0.009349 
0.009355 
0.009335 
0.009357 
##Execution time 
0.011961
```
On crée un script en bash qui calcule les données statistiques. En premier lieu on extrait les temps d'exécutions :
```
tile_data_static=$(grep -oP -m $i 
'(?<=##TILE static\s)[[0-9.\s]*(\s)*]*' 
<<< "$np_data_string" )
```
On calcule ensuite les différentes métriques avec des fonctions bash utilisant la commande  @f$awk @f$, exemple avec le calcul du Percent Imbalance Metric  @f$(\frac{x_{max}}{\overline{x}}-1)\times100 @f$
```
calculate_pim() {
  max=$1
  avg=$2
  echo $data | awk -v mean="$avg" -v max="$max" 
  'BEGIN{FS=" "; count=0; sum=0; sq_sum=0; cube_sum=0; quad_sum=0;}
  {
  
      }
  END{
      print (max/mean - 1) * 100;
  
  }'
}
```
On stocke dans des variables les différentes valeurs et on les insert dans un fichier  @f$\LaTeX @f$.
```
\begin{table}[htbp]
  \centering
  \caption{Statistiques pour le fichier $task_name}
  \begin{tabular}{|c|c|c|c|}
    \hline
    Statistique & Algebraic Tile & Tile (static) & Tile (dynamic) \\\ 
    \hline
    Skewness (g1)  & $g1_atile & $g1_tile & $g1_tile_dynamic \\\ 
    Kurtosis (g2)  & $g2_atile & $g2_tile & $g2_tile_dynamic \\\ 
    Coefficient de variation $ \frac{\sigma}{\overline{x}} $ & $std_dev_atile & $std_dev_tile & $std_dev_tile_dynamic\\\ 
    Percent Imbalance metric en \% & $pim_atile & $pim_tile & $pim_tile_dynamic\\\ 
    Coefficient de Gini  & $gini_atile & $gini_static & $gini_dynamic\\\ 
    Temps dexecution (s) & $exec_time_atile & $exec_time_tile & $exec_time_tile_dynamic \\\ 

    \hline
  \end{tabular}
\end{table}
```
Pour chaque jeu de données brutes on génère ainsi un histogramme des temps des threads et un tableau contenant les métriques d'équilibre de charge. 



***
  
    




