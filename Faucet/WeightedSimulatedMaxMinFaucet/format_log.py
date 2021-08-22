#!/usr/bin/python

file1 = open('log', 'r') 
file2 = open('log_formatted', 'w') 

lines = file1.readlines()
lines = lines[3:-1]

user = 10

arr = [str(x + 1) for x in range(user)]
i = 0

for line in lines:
    arr[i%user] = arr[i%user] + " " + line.rstrip()
    i+=1
    
for line in arr:
    file2.writelines(line + "\n")

file1.close() 
file2.close()
