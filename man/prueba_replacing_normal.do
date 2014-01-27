clear all
set mem 1g

run ../ado/parallel.ado
set obs 5000000
gen x = rnormal()

timer clear

preserve
timer on 1
do replacing_normal.do
timer off 1
restore

parallel setclusters 4
parallel do replacing_normal.do

