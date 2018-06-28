## Make the program_files.zip
sed 's|code/ado/||' ../../parallel.pkg > deliverable/parallel.pkg
#TODO: Fix
#Need to have files in same folder so give them different names
cp ../../ado/WIN/procenv.plugin deliverable/procenvWIN.plugin
cp ../../ado/WIN64A/procenv.plugin deliverable/procenvWIN64A.plugin  
cp ../../ado/WIN/procexec.plugin procexecWIN.plugin
cp ../../ado/WIN64A/procexec.plugin deliverable/procexecWIN64A.plugin  
cp ../../ado/WIN/prockill.plugin deliverable/prockillWIN.plugin
cp ../../ado/WIN64A/prockill.plugin deliverable/prockillWIN64A.plugin  
cp ../../ado/WIN/procwait.plugin deliverable/procwaitWIN.plugin
cp ../../ado/WIN64A/procwait.plugin deliverable/procwaitWIN64A.plugin  
#File list from pkg
zip -j deliverable/program_files.zip ../../ado/parallel.ado ../../ado/parallel_append.ado ../../ado/parallel_bs.ado ../../ado/parallel_sim.ado ../../ado/parallel.sthlp ../../ado/parallel_source.sthlp ../../ado/lparallel.mlib ../../ado/procenv.ado ../../ado/procexec.ado ../../ado/prockill.ado ../../ado/procwait.ado deliverable/*.plugin deliverable/parallel.pkg ../../stata.toc

## Make the submission.zip
#lyx --export pdf2 tex/lyxmain.lyx #should've already main since versioned
cd tex
lyx --export pdflatex lyxmain.lyx
cd ..

zip -j deliverable/submission.zip deliverable/program_files.zip deliverable/readme.txt tex/lyxmain.lyx tex/lyxmain.tex tex/lyxmain.pdf


#Cleanup
rm tex/lyxmain.tex
