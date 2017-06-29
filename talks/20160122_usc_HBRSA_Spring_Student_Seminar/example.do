clear all
set more off
set trace off

// Parallel way
sysuse auto, clear
parallel setclusters 4
timer on 1
parallel bs, reps(2000): reg price c.weig##c.weigh foreign rep
timer off 1

// Serial way
timer on 2
sysuse auto, clear
bs, reps(5000) nodots: reg price c.weig##c.weigh foreign rep
timer off 2

timer list
