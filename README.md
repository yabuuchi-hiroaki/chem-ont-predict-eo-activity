# Data and scripts for 'Structure-based chemical ontology improves chemometric prediction of antibacterial essential oils'

Essential oils are known to possess various biological activities.
However, it is difficult to predict their antibacterial activity because hundreds of compounds can be contribute the activity.
This repository stores the data and scripts to generate results in the paper [^1].

<p align="center"><img width="400" src="https://github.com/yabuuchi-hiroaki/chem-ont-predict-eo-activity/blob/images/overview.png"></p>

## Installation and Dependencies

The Python script 'HIC_continuous.py' needs following packages: scikit-learn, scipy, numpy

The R scripts need following packages: caret, pROC

Please make sure to install all dependencies prior to running the code.
The code presented here was implemented and tested in Anaconda ver.22.11.1 (Python ver.3.9.17).

## Usage
1. Download this repository.

2. Uncompress "data.zip" file to create "data" folder.
    - "data/cid_chemont" : chemical constituents of essential oil (
PubChem Compound ID) and their chemical ontology classes (ChemOnt ID)
    - "data/eo_in" : chemical composition of the essential oils in 
training and test dataset (corresoponding to Supplementary Table S2 of 
the paper)
    - "data/eo_assay" : chemical composition of the essential oils 
analyzed by GC/MS (corresoponding to Supplementary Table S5 of the paper 
and Supplementary Table S5 of Yabuuchi et al [^2] )

3. Download chemical ontology (ChemOnt) file from [ClassyFire web site]( 
http://classyfire.wishartlab.com/downloads), and save in the "data" 
folder.

4. Run the following commands to prepare input files.
```bash
$ perl src/pathcomb.pl data/ChemOnt_2_1.obo data/cid_chemont data/eo_in > out/pathcomb
$ perl src/add_chemclassEO.pl data/eo_in out/pathcomb > out/eocls
$ perl src/add_chemclassEO.pl data/eo_assay out/pathcomb > out/eocls_assay
$ perl src/divide_by_pubdate.pl out/eocls 2020 out/eocls_t out/eocls_p
$ perl src/hist_2group.pl out/eocls_t > out/hist
```
The output files are:
    - pathcomb: All paths from root to leaf nodes in ChemOnt hierarchy
    - eocls_t: training dataset
    - eocls_p: test dataset
    - eocls_assay: bioassay dataset

5. Run the following commands to perform feature selection using 
hierarchical information criterion (HIC).
The HIC algorithm, which was originally developed by Mirtchouk et al [^3]
, was modified to calculate HIC between continous (chemical composition) 
and discrete (activity label) data in this study.
```bash
$ python src/HIC_continuous.py out/pathcomb out/hist data/weight.csv > out/hic
```

6. Set your R working directory to the root directory of the project.

7. Run a R script "src/compChemont_vs_comp.R".
    - The script performs training & prediction using all features, and 
calculate the area under the ROC curve.

8. Run a R script "src/topK_perf.R".
    - The script performs training & prediction using top K features. 

9. Run a R script "src/predEO.R".
    - The script performs training & prediction for commercially 
available oils.

## References
[^1]: Yabuuchi H et al. Structure-based chemical ontology improves 
chemometric prediction of antibacterial essential oils.
 Research Square (posted on Mar 25, 2024).
[^2]: Yabuuchi H et al. In vitro and in silico prediction of 
antibacterial interaction between essential oils via graph embedding 
approach.
 Sci Rep. 2023, 13(1):18947. doi: [10.1038/s41598-023-46377-5](
https://doi.org/10.1038/s41598-023-46377-5).

[^3]: Mirtchouk M et al. Hierarchical information criterion for variable 
abstraction.
 Proc Mach Learn Res 2021, 149:440–460. PMCID: [PMC8782429](
https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8782429/).
 GitHub: [https://github.com/health-ai-lab/HIC](https://github.com/health-ai-lab/HIC).
 
