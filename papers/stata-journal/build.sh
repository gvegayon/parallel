## Make the program_files.zip
#Need to have files in same folder so give them different names
cp ../../ado/WIN/procenv.plugin deliverable/procenvWIN.plugin
cp ../../ado/WIN64A/procenv.plugin deliverable/procenvWIN64A.plugin  
cp ../../ado/WIN/procexec.plugin deliverable/procexecWIN.plugin
cp ../../ado/WIN64A/procexec.plugin deliverable/procexecWIN64A.plugin  
cp ../../ado/WIN/prockill.plugin deliverable/prockillWIN.plugin
cp ../../ado/WIN64A/prockill.plugin deliverable/prockillWIN64A.plugin  
cp ../../ado/WIN/procwait.plugin deliverable/procwaitWIN.plugin
cp ../../ado/WIN64A/procwait.plugin deliverable/procwaitWIN64A.plugin  
#Transform ado/WIN/procenv.plugin -> procenvWIN.plugin
sed -e 's|ado/\([A-Z1-9]*\)/\([a-z]*\)|\2\1|' -e 's|ado/||' ../../parallel.pkg > deliverable/parallel.pkg
#File list from pkg
zip -j deliverable/package_files.zip ../../ado/parallel.ado ../../ado/parallel_append.ado ../../ado/parallel_bs.ado ../../ado/parallel_sim.ado ../../ado/parallel.sthlp ../../ado/parallel_source.sthlp ../../ado/lparallel.mlib ../../ado/procenv.ado ../../ado/procexec.ado ../../ado/prockill.ado ../../ado/procwait.ado deliverable/*.plugin deliverable/parallel.pkg ../../stata.toc

## Make the paper_source.zip
cd tex
lyx --export pdflatex parallel.lyx
#lyx --export pdf2 lyxmain.lyx #should've already main since versioned
zip ../deliverable/paper_source.zip parallel.lyx parallel.tex tables_and_figures/diagram.tex tables_and_figures/parallel_benchmarks_test=boottest.tex tables_and_figures/parallel_benchmarks_test=simtest.tex parallel.bib statapress.layout statapress.cls sj.sty sj.bst tl.eps tr.eps tl.pdf tr.pdf stata.sty multind.sty pagedims.sty
rm tex/lyxmain.tex
cd ..

zip -j deliverable/paper_examples.zip tex/01_parallel_benchmark.do tex/02_parallel_benchmark.do tex/BOOTTEST.ado tex/make_polynomial.do tex/mysim.ado tex/paper_examples.do tex/print_dots.ado tex/SIMTEST.ado tex/20161102_parallel-bechmark_nreps=1000.dta

## Make the submission.zip
zip -j deliverable/submission.zip deliverable/package_files.zip deliverable/paper_source.zip deliverable/paper_examples.zip tex/parallel.pdf deliverable/readme.txt