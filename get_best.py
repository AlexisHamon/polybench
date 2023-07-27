import csv
import glob
import sys
def get_best_execution_time(data,exec_type0,best_div1, best_div2, best_div3, best_flag, best_extra,best_time):
    for row in data:
        div1 = int(row['DIV1'])
        div2 = int(row['DIV2'])
        div3 = int(row['DIV3'])
        flags = row['CFLAGS']
        exec_type = row['EXEC_TYPE']
        extra = row['EXTRA_FLAGS']
        time = float(row['TIME'])
        if time < best_time and str(exec_type0) == str(exec_type):
            best_time = time
            best_div1, best_div2, best_div3, best_flag, best_extra = div1, div2, div3, flags, extra

    return best_div1, best_div2, best_div3, best_flag, best_extra, best_time
#Le nom du fichier est le premier argument
filename = sys.argv[1]
#Type d'execution
exec_type = sys.argv[2]

#On cherche dans tous les fichiers csv qui commence par le nom du fichier
best_div1, best_div2, best_div3, best_flag, best_extra = None, None, None, None, None
best_time = float('inf')

files=glob.glob("../mark6/processed_data/"+filename+"_*.csv")
for file in files:
    #on affiche le nom du fichier
    # print(file)
    with open(file, 'r') as file:
        csv_reader = csv.DictReader(file)
        data = list(csv_reader)

    # Récupérer les meilleurs DIV1, DIV2, DIV3 et FLAGS
    best_div1, best_div2, best_div3, best_flag, best_extra, best_time = get_best_execution_time(data,exec_type,best_div1, best_div2, best_div3, best_flag, best_extra,best_time)
    # print(best_time)





# Afficher les résultats
# print("DIV1 = ",best_div1)
# print("DIV2 = ",best_div2)
# print("DIV3 = ",best_div3)
print(best_div1)
print(best_div2)
print(best_div3)
# print(best_time)
print(best_flag)
print(best_extra)   