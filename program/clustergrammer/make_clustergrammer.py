'''
Python 2.7
The clustergrammer python module can be installed using pip:
pip install clustergrammer

or by getting the code from the repo:
https://github.com/MaayanLab/clustergrammer-py
'''
import sys
import os
from clustergrammer import Network
import pandas as pd
net = Network()
filename = sys.argv[1]
outname = sys.argv[2]
wd = sys.argv[3]
jobid =  sys.argv[4]
use_user_label = sys.argv[5]

os.chdir(wd)
user_label=jobid + '_user_label_name.txt'
df=pd.read_csv(user_label, sep='\t', header=0)
unique_array=df.iloc[:,0].unique()  ## equal to sorted provided raw cell label
#df['num_unique'] = df.nunique(axis=1)

#print(df.iloc[0,:].unique())

net.load_file(filename)

color_array3=["#5A5156","#F6222E","#FE00FA","#16FF32","#3283FE","#FEAF16","#B00068","#1CFFCE","#90AD1C","#2ED9FF","#DEA0FD","#AA0DFE","#F8A19F","#325A9B","#C4451C","#1C8356","#85660D","#B10DA1","#FBE426","#1CBE4F","#FA0087","#FC1CBF","#F7E1A0","#C075A6","#782AB6","#AAF400","#BDCDFF","#822E1C",
"#B5EFB5","#7ED7D1","#1C7F93","#D85FF7","#683B79","#66B0FF","#3B00FB"]
if use_user_label == '0' or use_user_label == '1':
    for i in range(len(color_array3)):
        label='Predicted label: _'+str(i+1)+'_'
        net.set_cat_color(axis='col', cat_index=1, cat_name=label, inst_color=color_array3[i])
		
if outname[0:2] != 'CT' and use_user_label == '2': 
    for i in range(len(color_array3)):
        label='Predicted label: _'+str(i+1)+'_'
        net.set_cat_color(axis='col', cat_index=1, cat_name=label, inst_color=color_array3[i])
				
if outname[0:2] == 'CT' or outname[0:2] == 'mo':
	if use_user_label == '2':
		for j in range(len(unique_array)):
			userlabel='User\'s label: _'+str(unique_array[j]).replace(" ", "_")+'_'
			net.set_cat_color(axis='col', cat_index=1, cat_name=userlabel, inst_color=color_array3[j])
			
if outname[0:2] == 'CT' or outname[0:2] == 'mo':    
	if use_user_label == '2':        
		for i in range(len(color_array3)):
			label='Predicted label: _'+str(i+1)+'_'
			net.set_cat_color(axis='col', cat_index=2, cat_name=label, inst_color=color_array3[34-i])


net.cluster(dist_type='cos', enrichrgram=True, run_clustering=False)
# write jsons for front-end visualizations
out = wd + 'json/' + outname + '.json'
net.write_json_to_file('viz', out, 'indent')
