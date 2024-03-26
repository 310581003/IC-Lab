# -*- coding: utf-8 -*-
"""
Created on Wed Mar 22 22:21:08 2023

@author: HUANG TZU-HSUAN
"""

import numpy as np
import random

Pattern_num = 100
input_path = 'input.txt'
output_path = 'output.txt'


for k in range (0, Pattern_num):
    matrix_size =0
    matrix = []
    matrix_idx = []
    while (matrix_size!=2 and matrix_size!=4 and matrix_size!=8 and matrix_size!=16):      
        matrix_size = random.randrange(2,17,2)
        print(matrix_size)
    with open(input_path, 'a') as f:
        if matrix_size == 2:
            f.write(str(0)+'\n')
        elif matrix_size == 4:
            f.write(str(1)+'\n')
        elif matrix_size == 8:
            f.write(str(2)+'\n')
        elif matrix_size == 16:
            f.write(str(3)+'\n')
            
        
    for i in range (0, matrix_size*matrix_size*32):
        matrix_element = random.randint(-128,127)
        matrix.append(matrix_element)
        with open(input_path, 'a') as f:
            f.write(str(matrix_element)+'\n')
    
    for j in range (0,10):
        A=[]
        B=[]
        C=[]
        mode = random.randint(0,3)
        with open(input_path, 'a') as f:
            f.write(str(mode)+'\n')
        for z in range (0, 3):
            index = random.randint(0,31)
            matrix_idx.append(index)
            with open(input_path, 'a') as f:
                f.write(str(index)+'\n')
        
        for y in range(0,matrix_size*matrix_size):
            A.append(matrix[matrix_idx[3*j]*matrix_size*matrix_size]+y)
            B.append(matrix[matrix_idx[3*j+1]*matrix_size*matrix_size]+y)
            C.append(matrix[matrix_idx[3*j+2]*matrix_size*matrix_size]+y)
            
        A = np.array(A).reshape((matrix_size,matrix_size))
        B =  np.array(B).reshape((matrix_size,matrix_size))
        C = np.array(C).reshape((matrix_size,matrix_size))
        
      
        if (mode==0):
            R =A.dot(B).dot(C)
            out_value = R.trace()
        elif(mode==1):
            R= (A.T).dot(B).dot(C)
            out_value = R.trace()
        elif(mode==2):
            R= A.dot(B.T).dot(C)
            out_value = R.trace()
        elif(mode==3):
            R= (A).dot(B).dot(C.T)
            out_value = R.trace()
            
        with open(output_path, 'a') as f:
            f.write(str(out_value)+'\n')
            
        
        
            
    