#!/bin/sh
if [ $1 = 't3' ]
then

cat > $3 <<DATA
1430194	T	1	Cancer risks from germline p53 mutations.
1567683	T	1	The p53 gene in human cancer.
12532223	T	1	p53 as a prognostic factor in adrenocortical tumors of adults and children.
12532223	A	1	Mutations of the tumor suppressor gene p53 have been considered to be important determinants in several kinds of human cancer.
12532223	A	2	Accumulation of p53 protein has been reported to correlate with more aggressive clinical behavior in some neoplasms.
12532223	A	3	The role of p53 expression in adrenal cortical tumors (ACT) has not been elucidated but some studies have suggested its correlation with malignant behavior.
12532223	A	4	Our objective was to determine if there is a correlation between the expression of immunoreactive p53 and the biological behavior of ACT.
DATA

elif [ $1 = 't4' ]
then

cat > $3 <<DATA
1430194	T	1	disease	Cancer	0	6	UMLS:C1306459
1430194	T	1	human_gene	p53	27	30	UNIPROT:P04637
DATA

else

cat > $3 <<DATA
9841419	A|	A
1316123	in|	類似の
153200	mitochondrial|yeast|	ミトコンドリアの|酵母
11826483	Mycobacterium|	Mycobacterium
6060646	in|A|	類似の|A
18203626	.|mitochondrial|	沸点|ミトコンドリアの
9662622	mouse|Mouse|	マウス|Mouse
18936532	cancer|	癌
1991590	human|be|	ヒト|ベリリウム
9662630	mouse|Mouse|	マウス|Mouse
DATA

fi
