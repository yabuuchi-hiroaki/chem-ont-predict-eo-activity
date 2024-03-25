# Hierarchical information criterion for continuous data
#
#

import math
import sys
from scipy.stats import ttest_rel
import numpy as np
import pickle
from itertools import repeat
from sklearn.feature_selection import mutual_info_classif
from collections import defaultdict

nested_dict = lambda: defaultdict(nested_dict)
is_des = nested_dict()

##### Checks the decendants #####

def define_isDes(ddepth, pathcomb, is_des):
    for x in ddepth.keys():
        for y in ddepth.keys():
            is_des[x][y] = 0;
    for x in pathcomb.keys():
        for i1 in range(len(pathcomb[x])-1):
            for i2 in range(i1+1, len(pathcomb[x])):
                is_des[ pathcomb[x][i1] ][ pathcomb[x][i2] ] = 1
    return is_des

##### Gets all leaf nodes in tree 'd' #####

def getleaf(f, d, dans):
    if f in d:
        for q in d[f]:
            if q is not None:
                currans = getleaf2(q, d, dans)
                if currans  is not None:
                    dans[currans] = 1
    else:
        if f is not None:
            return f
    return dans

##### getleaf helper function to iterate over all children #####

def getleaf2(f, d, dans):
    if f in d:
        for q in d[f]:
            if q is not None:
                currans = getleaf2(q, d, dans)
                if currans  is not None:
                    dans[currans] = 1
    else:
        if f is not None:
            return f

##### Fills the depth of each node #####

def fillDepth(f, d, ddepth):
    if f in d:
        for q in d[f]:
            if q in ddepth:
                continue
            ddepth[q] = ddepth[f] + 1
            fillDepth(q, d, ddepth)

##### Imports the weights #####

def importWeights(weightsfn):
    f = open(weightsfn,"r")
    f1 = f.readlines()
    for x in f1:
        a = x.split(",")
        if a[0].lower() == "branch":
            weightbranch = float(a[1])
        elif a[0].lower() == "tree":
            weighttree = float(a[1])
        else:
            continue
    return weightbranch, weighttree

##### Imports an ontology in the form of a 2 column seperated list #####

def importOnto(ontofn):
    f = open(ontofn,"r")
    f1 = f.readlines()
    d = {}
    pathcomb = {}
    for x in f1:
        if len(x) <= 1 or x[0] == "#":
            continue
        a = x.split("\t")
        if a[1][-1] == '\n':
            a[1] = a[1][:-1] #take out the \n
        b = a[1].split(",")
        for i in range( len(b) ):
            if a[0] in pathcomb:
                pathcomb[ a[0] ].append( b[i] )
            else:
                pathcomb[ a[0] ] = [ b[i] ]
        for i1 in range( len(b) -1 ):
            if b[i1] in d:
                d[ b[i1] ].append( b[i1+1] )
            else:
                d[ b[i1] ] = [ b[i1+1] ]
    ddepth = {}
    ddepth['root'] = 0
    fillDepth('root', d, ddepth)
    highestLevel=0 #init to find the longest depth
    for kdep in ddepth:
        if ddepth[kdep] > highestLevel:
            highestLevel = ddepth[kdep]
    return d, pathcomb, ddepth, highestLevel

##### Imports an ontology in the form of a dictionary num with keys #####

def importOntoNum(ontonumfn):
    f=open(ontonumfn, "r")
    f1 = f.read().splitlines()  # f.readlines()
    num={}
    num['root']={}
    num['root']['d1']=0  # the parent is root
    num['root']['d2']=0  # the parent is root
    for x in f1:
        if len(x)<=1 or x[0]=="#":
            continue
        a = x.split("\t")
        if a[0] not in num:
            num[ a[0] ] = {}
        num[a[0]]['d1'] = a[1]
        num[a[0]]['d2'] = a[2]
    return num

##### Returns the sigmoid of x #####

def sigmoid(x):
    try:
        return 1.0/(1+math.exp(-x))
    except:
        return 0 

##### Returns the maximum statistical signifincace based on a paired t-test for the whole tree #####

def rc2_tree(num, ddepth, highestLevel, weighttree, toprint=False):
    pdict = {}
    pdict2 = {}   # maximum z-value for each pair
    if toprint:
        print ("Node 1    Node 2    P-value tree")
    if weighttree == 0:
        for x in sorted(ddepth.keys()):
            pdict2[x] = 0
        return pdict2
    for x in sorted(ddepth.keys()):
        xd1 = [float(item) for item in num[x]['d1'].split(",")]
        xd2 = [float(item) for item in num[x]['d2'].split(",")]
        for y in sorted(ddepth.keys()): 
            if x==y or x=='root' or y=='root': 
                continue
            yd1 = [float(item) for item in num[y]['d1'].split(",")]
            yd2 = [float(item) for item in num[y]['d2'].split(",")]
            stat1 = ttest_rel(xd1, yd1)
            stat2 = ttest_rel(xd2, yd2)
            pval = min(stat1[1], stat2[1])
            if math.isnan(pval):
                pval = 1
            if toprint:
                print (x,"       ",y,"       ",'{0:0.3f}'.format(pval))
            if x in pdict:
                    pdict[x].append(pval)
            else:
                    pdict[x]=[pval]
            if y in pdict:
                    pdict[y].append(pval)
            else:
                    pdict[y]=[pval]
    for x in sorted(ddepth.keys()): # pdict:
        if x in pdict:
            pdict2[x] = max(pdict[x])
        else:
            pdict2[x] = 1
        if math.isnan(pdict2[x]):
            pdict2[x] = 1
    return pdict2


##### Returns the maximum statistical signifincace based on a pairrd t-test for each node in branch #####

def rc2_branch(num, pathcomb, ddepth, highestLevel, is_des, weightbranch, toprint=False):
    pdict = {}
    if toprint:
        print ("Node 1    Node 2    P-value branch")
    for x2_k in sorted(pathcomb.keys()):
        x2 = pathcomb[x2_k][-1]
        for x in sorted(pathcomb[x2_k]):
            xd1 = [float(item) for item in num[x]['d1'].split(",")]
            xd2 = [float(item) for item in num[x]['d2'].split(",")]
            for y in sorted(pathcomb[x2_k]):
                if x==y or x=='root' or y=='root':
                    continue
                if not is_des[x][y] and not is_des[y][x]:
                    continue
                pval = 0
                if weightbranch > 0:
                    yd1 = [float(item) for item in num[y]['d1'].split(",")]
                    yd2 = [float(item) for item in num[y]['d2'].split(",")]
                    stat1 = ttest_rel(xd1, yd1)
                    stat2 = ttest_rel(xd2, yd2)
                    pval = min(stat1[1], stat2[1])
                    if math.isnan(pval):
                        pval = 1
                if toprint:
                    print (x,"       ",y,"       ",'{0:0.4f}'.format(pval))
                pval_x = 0
                pval_y = 0
                if is_des[x][y]:  # x is ancestor
                    pval_y = pval
                else:
                    pval_x = pval
                if (x2,x) in pdict:
                    pdict[(x2,x)].append(pval_x)
                else:
                    pdict[(x2,x)] = [pval_x]
                if (x2,y) in pdict:
                    pdict[(x2,y)].append(pval_y)
                else:
                    pdict[(x2,y)] = [pval_y]
    pdict2 = {}  # maximum z-value for each pair
    for x in pdict:
        pdict2[x] = max(pdict[x])
        if math.isnan(pdict2[x]):
            pdict2[x] = 1
    return pdict2

##### Calculates the HIC value based on the HIC formula #####

def calcHIC(num, d, pathcomb, ddepth, weightbranch, weighttree, highestLevel, is_des, toprint=False):
    pr = {}
    pdict_tree = rc2_tree(num, ddepth, highestLevel, weighttree, False)
    pdict_branch = rc2_branch(num, pathcomb, ddepth, highestLevel, is_des, weightbranch, False)
    x_mi = []
    name_mi = {}
    i = -1
    for x in sorted(ddepth.keys()):
        xd1 = [float(item) for item in num[x]['d1'].split(",")]
        xd2 = [float(item) for item in num[x]['d2'].split(",")]
        i += 1
        x_mi.append(xd1 + xd2)
        name_mi[x] = i
    y_mi = list( repeat(1, len(xd1))) + list(repeat(0, len(xd2)))
    mi = mutual_info_classif(np.transpose(x_mi), y_mi, discrete_features=False, n_neighbors=32, random_state=1)
    tmphictree={}
    for x2_k in sorted( pathcomb.keys() ):
        x2 = pathcomb[x2_k][-1]
        maxlevel = len( pathcomb[x2_k] )
        if maxlevel == 1:
            continue
        for x in pathcomb[x2_k]:
            if x == 'root':
                continue
            currlevel = ddepth[x]
            if currlevel > maxlevel or x2 == x:
                currlevel = maxlevel
            scaled_mi = mi[name_mi[x]] / max(mi)
            scaled_dd = math.log(currlevel + maxlevel, maxlevel) - 1
            HIC = scaled_mi - scaled_dd - weightbranch * pdict_branch[x2, x] - weighttree * pdict_tree[x]
            if x not in tmphictree:
                tmphictree[x]=[HIC]
            else:
                tmphictree[x].append(HIC)
            if toprint:
                print(x2, x, currlevel, maxlevel, mi[name_mi[x]], max(mi), 
                     pdict_branch[x2, x], pdict_tree[x], HIC, sep='\t')
    hictree = {}                        
    for icd9 in tmphictree:
        hictree[icd9] = max(tmphictree[icd9])
    return hictree

##### Main #####

if __name__ == '__main__':
    if len(sys.argv)==4:
        ontofn = sys.argv[1]
        ontonumfn = sys.argv[2]
        weightsfn = sys.argv[3]
        num = importOntoNum(ontonumfn)
        weightbranch, weighttree = importWeights(weightsfn)
        dd, pathcomb, ddepth, highestLevel = importOnto(ontofn)
        is_des = define_isDes(ddepth, pathcomb, is_des)
        toprint = False # True
        hictree=calcHIC(num, dd, pathcomb, ddepth, weightbranch, weighttree, highestLevel, is_des, toprint)
        hictree_s = sorted(hictree.items(), key=lambda x:x[1], reverse=True)
        print("HIC_score", "ID", sep='\t')
        for i in range( len(hictree_s) ):
            print(hictree_s[i][1], hictree_s[i][0], sep='\t')
    else:
        print ("Usage: python HIC_continuous.py <ontology-file> <ontologynum-file> <weight-file>")
