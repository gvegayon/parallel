{smcl}
{* *! version 1.20.0 19mar2019}{...}
{cmd:help parallel}{right:also see:  {net "describe miparallel, from(http://fmwww.bc.edu/RePEc/bocode/m)":miparallel}}
{hline}

{title:Title}

{phang}
{bf:parallel} {hline 2} Stata module for Parallel computing

{title:Index}

{p2colset 5 31 31 2}
{p2col:{bf:{ul:Sections}}}{p_end}

{p2col: 1.  {help parallel##syntax:Syntax}}Command syntax.{p_end}
{p2col: 2.  {help parallel##description:Description}}Command description.{p_end}
{p2col: 3.  {help parallel##details:Details}}How does parallel works.{p_end}
{p2col: 4.  {help parallel##append_how:Parallel Append}}Using -parallel append- syntax.{p_end}
{p2col: 5.  {help parallel##caveats:Caveats}}Things to consider before using parallel.{p_end}
{p2col: 6.  {help parallel##tech:Technical note}}Some details under the hood.{p_end}
{p2col: 7.  {help parallel##examples:Examples}}Some examples using parallel{p_end}
{p2col: 8.  {help parallel##saved_results:Saved results}}A list of parallel's save results{p_end}
{p2col: 9.  {help parallel##development:Development}}Up-to-date version and bug reporting{p_end}
{p2col: 10. {help parallel##source:Source code}}parallel's (MATA) source code{p_end}
{p2col: 11. {help parallel##authors:Authors}}Authors behind parallel{p_end}
{p2col: 12. {help parallel##contrib:Contributors}}Notable contributors{p_end}
{p2col: 13. {help parallel##also:Also see}}Other modules related to parallel{p_end}
{p2col: 14. {help parallel##faqs:FAQs}}Frequently Asked Questions{p_end}


{p2colset 5 32 32 2}
{p2col:{bf:{ul:Available commands}}}{p_end}

{p2col: 1.  {help parallel##initialize:parallel initialize}}Setting the number of child processes.{p_end}
{p2col: 2.  {help parallel##numprocessors:parallel numprocessors}}Getting the number of processors on the system.{p_end}
{p2col: 3.  {help parallel##do:parallel do}}Parallelizing a do-file.{p_end}
{p2col: 4.  {help parallel##prefix:parallel : (prefix)}}Parallelizing a Stata command (parallel prefix).{p_end}
{p2col: 5.  {help parallel##bs:parallel bs}}Parallel bootstrapping.{p_end}
{p2col: 6.  {help parallel##bs:parallel sim}}Parallel simulate.{p_end}
{p2col: 7.  {help parallel##append:parallel append}}Multiple file processing and appending.{p_end}
{p2col: 8.  {help parallel##clean:parallel clean}}Removing auxiliary files.{p_end}
{p2col: 9.  {help parallel##printlog:parallel printlog}}Checking out child processes' log files.{p_end}
{p2col:10.  {help parallel##version:parallel version}}Query parallel current version.{p_end}


{marker syntax}{...}
{title:1. Syntax}

{col 5}{hline}{marker initialize}{...}
{pstd}Setting the number of child processes (threads/processors)

{p 8 17 2}
{cmdab:parallel initialize} [ # , {opt f:orce} 
{opt s:tatapath}({it:{help filename:stata_path}})
{opt i:ncludefile}({it:{help filename:filename}})
{opt h:ostnames}({it:string})
{opt ssh}({it:string})
{opt proc:exec}({it:int})]

{col 5}{hline}{marker numprocessors}{...}
{pstd}Getting the number of processors on the system

{p 8 17 2}
{cmdab:parallel numprocessors}

{col 5}{hline}{col 2}{marker do}{...}
{pstd}Parallelizing a do-file

{p 8 17 2}
{cmdab:parallel do}
{it:{help filename}} [, {opt by}({it:{help varlist}}) {opt f:orce} 
  {opt nod:ata} {opt set:parallelid}({it:pll_id}) {it:execution_options}]

{col 5}{hline}{marker prefix}{...}
{pstd}Parallelizing a Stata command (parallel prefix)

{p 8 17 2}
{cmdab:parallel} [, {opt by}({it:{help varlist}}) {opt f:orce} {opt k:eep}
 {opt nod:ata} {opt set:parallelid}({it:pll_id}) {it:execution_options}]:
{it:command}

{col 5}{hline}{marker bs}{...}
{pstd}Parallel bootstrapping

{p 8 17 2}
{cmdab:parallel bs}
[, {opt exp:ression}({it:{help exp_list}}) 
 {it:execution_options} {it:{help bs:bs_options}}
 ] [{cmd::} {it:command}]

{col 5}{hline}{marker sim}{...}
{pstd}Parallel simulate

{p 8 17 2}
{cmdab:parallel sim}
[ , 
 {opt exp:ression}({it:{help exp_list}})
 {it:execution_options} {it:{help simulate:sim_options}}
 ] [{cmd::} {it:command}]

{col 5}{hline}{marker append}{...}
{pstd} Multiple file processing and appending

{p 8 17 2}
{cmdab:parallel append}
 [{it:{help filename:file(s)}}] ,
 {opt d:o}({it:cmd|dofile}) [{opt in}({it:{help in}}) {opt if}({it:{help if}})
 {opt e:xpression}({it:expand expression (see details)})
 {it:execution_options} ]

{col 5}{hline}{marker clean}{...}
{pstd}Removing auxiliary files

{p 8 17 2}
{cmdab:parallel clean} [, {opt e:vent}({it:pll_id}) {opt a:ll} {opt f:orce}]

{col 5}{hline}{marker printlog}{...}
{pstd}Checking out child processes' logfiles by printing the output.

{p 8 17 2}
{cmdab:parallel printlog} [{it:#}] [, {opt e:vent}({it:pll_id})]

{p 4 17 2}
Checking out child processes' logfiles by showing the output in a view window.

{p 8 8 2}
{cmdab:parallel viewlog} [{it:#}] [, {opt e:vent}({it:pll_id})]

{col 5}{hline}{marker version}{...}
{pstd}Query {cmd:parallel} current version

{p 8 17 2}
{cmdab:parallel version}


{synoptset 15 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Setting the number of child processes}
{synopt:{opt #}} The number of child processes. If omitted the default is max(floor(num_processors*0.75),1){p_end}
{synopt:{opt f:orce}}Overrides the restriction on using more child processes than processors on your machine (see the 
{help parallel##warnings:WARNING} in description). This option is assumed when specifying {opt hostnames}.{p_end}
{synopt:{opt s:tatapath}}File path. {cmd:parallel} tries to automatically identify
Stata's exe path. By using this option you will override this and force 
{cmd:parallel} to use a specific path to stata.exe.{p_end}
{synopt:{opt i:ncludefile}}File path. This file will be included before parallel commands
are executed. The target purpose for this is to allow one to copy over preferences that
{cmd:parallel} does not copy automatically.{p_end}
{synopt:{opt h:ostnames}} a space delimited list of hostnames. For the local machine, use {it:localhost}.
Work will be assigned in the order of the list and the list elements will be re-used if num child processes is longer than the list.
An example would be {it:localhost node2 node3}.
If no option is provided, then {it:localhost} is assumed. Leave blank for local execution.{p_end}
{synopt:{opt ssh}}The command used to connect to remote machines.
If none is provided, this will be {it:ssh}. This option is not needed for local execution.{p_end}
{synopt:{opt proc:exec}} On Windows, controls how child processes are spawned. 
The default value 2 will launch them in a hidden desktop (they can still be seen in the task manager)
so that the child applications don't briefly steal the window focus (which is annoying). 
With value 1 the child processes will be launched in the user's desktop, will be launch auto-minimized, but will still briefly steal the focus. 
and will steal focus and perhaps briefly show the windows of the child processes.{p_end}

{syntab:{it:execution_options}}
{synopt:{opt k:eep}}Keeps auxiliary files generated by {cmd:parallel}. 
Use this and the next option with care as there can be many file that take up space.{p_end}
{synopt:{opt keepl:ast}}Keeps auxiliary files and remove those last time saved 
during the current session.{p_end}
{synopt:{opt prog:rams}}A list of programs to be passed to each child process. 
To do this, {cmd:parallel} needs to echo the contents of those programs to the output window. 
If {cmd:parallel} is 
being run from inside an ado (say {it:my_cmd.ado}) and you need to access local subroutines (other programs
defined in the ado beside the primary {it:my_cmd}), then you must pass their names in this option as
{it:my_cmd.local_subroutine_name} for them to be accessible.{p_end}
{synopt:{opt m:ata}}If the algorithm needs to use mata objects, this option allows
to pass to each child process every mata object loaded in the current session (including functions). 
Note that when mata objects are loaded into the child processes they will have different 
locations and therefore pointers may no longer be accurate.{p_end}
{synopt:{opt nog:lobal}}Avoid passing current session's globals to the child processes.{p_end}
{synopt:{opt s:eeds}}Numlist. With this option the user can pass an specific seed to be
used within each child process.{p_end}
{synopt:{opt randt:ype}}String. Tells parallel whether to use the current seed
(-current-), the current datetime (-datetime-) or random.org API (-random.org-) to
generate the seeds for each child processes (please read the Description section).{p_end}
{synopt:{opt proc:essors}}Integer. If running on StataMP, sets the number of processors
each child process should use. Default value is 0 (do nothing).{p_end}
{synopt:{opt t:imeout}}Integer. If a child process hasn't started, how much time in seconds
does {cmd:parallel} has to wait until assume that there was a connection error and thus
the child process won't start. Default value is 60.{p_end}
{synopt:{opt out:putopts}} A list of option names that are aggregating output options.
{cmd:parallel} automtically aggregates main data from child processes. 
Often, though, a program will aggregate more than one type of data.
{opt outputopts} allows generic file-based aggregation (appending). 
A sequential call such as {cmd:my_prog, output1(outputfile.dta)} can be converted to
{cmd:parallel, outputopts(output1): my_prog, output1(outputfile.dta)}.
{cmd:parallel} will execute each child process with its own file passed to {opt output1}
and at the end, append them all and save it to {it:outputfile.dta}.{p_end}
{synopt:{opt det:erministicoutput}}will eliminates displayed output that would vary 
depending on the machine (e.g. timers, seeds, and number of parallel child processes) so 
that log files can be easily compared across runs. Errors are still printed.{p_end}

{syntab:Byable parallelization}
{synopt:{opt by}}Varlist. Tells the command through which observations the current dataset 
can be divided, avoiding stories (panel) splitting over two or more child processes.
The semantics for {opt by} are not the same as for Stata.
When Stata implements {cmd:by}, the command that is run will only see a section of the data where the by-variables are the same.
{cmd:parallel}'s semantics are that no observations with the same {opt by}-values will be in different child processes. 
It pools together combinations when there are fewer child processes than by-var combinations. 
If you need Stata-style semantics, the solution is to add {cmd:by} in the subcommand. 
For example, {cmd: parallel, by(byvar): by byvar: egen x_max = max(x)}.
{p_end}
{synopt:{opt f:orce}}When using {opt by}, {cmd:parallel} checks whether if the dataset
is properly sorted. By using {opt force} the command skips this check.{p_end}

{syntab:Parallel bootstrap}
{synopt:{opt exp:ression}}An {help exp_list} to be passed to the {help bootstrap} command.{p_end}
{synopt:{opt bs_options}} Further options to be passed to the {help bootstrap} command, including the optional reps() parameter.

{syntab:Parallel simulate}
{synopt:{opt exp:ression}}An {help exp_list} to be passed to the {help simulate} command.{p_end}
{synopt:{opt sim_options}} Further options to be passed to the {help simulate} command, including the required reps() parameter.

{syntab:Multiple file processing and appending}
{synopt:{opt d:o}}Stata cmd or dofile. 
Note that {cmd: parallel do} does not support passing options to the do-file. 
If you need arguments then use the prefix style. {p_end}
{synopt:{opt files}}Explicit list of files to process.{p_end}
{synopt:{opt e:xpression}}String. Expression representing file names in the form of
"{it:{help fmt:%fmts}}, {it:{help numlist: numlist1 [, numlist2 [, ...]]}}"

{syntab:Removing auxiliary files}
{synopt:{opt e:vent}}String. Specifies which executed (and stored) event's files should be removed.{p_end}
{synopt:{opt a:ll}}Tells {cmd:parallel} to remove every remnant auxiliary files generated by it
in the current directory.{p_end}
{synopt:{opt f:orce}}Forces the command to remove (apparently) in-use auxiliary files. Otherwise
these will not get deleted.{p_end}

{syntab:Other options}
{synopt:{opt e:vent}}String. With printlog and viewlog this specifies which event's log files should be displayed.{p_end}
{synopt:{opt set:parallelid}}Programmers' option. Forces parallel to use an specific
id ({it:pll_id}) (see {help parallel##tech:Technical Notes}).{p_end}
{synopt:{opt nod:ata}}Tells {cmd:parallel} not to use loaded data and thus
not to try splitting or appending anything.{p_end}

{marker description}{...}
{title:2. Description}

{pstd}
-{cmd:parallel}- allows to implement parallel computing, without having StataMP, 
substantially reducing computing time. Specially suitable for bootstrapping and
simulations, parallel includes out-of-the-box tools for implementing such
algorithms.
{p_end}

{pstd}
In order to use -{cmd:parallel}- it is necessary to set the number of desired child processes
with which the user wants to work with. To do this the user should use -{cmd:parallel initialize}-
syntaxes, replacing {it:#} with the desired number of child processes. Setting more child processes
than physical cores the user's computer has it is not recommended (see the {help parallel##warnings:WARNING}
in description).
{p_end}

{pstd}
-{cmd:parallel do}- is the equivalent (wrapper) to -do-. When using this syntax
parallel runs the dofile in as many child processes as there where specified by the user, this is,
start {cmd:$PLL_CHILDREN} Stata instances in batch mode. By default the
loaded dataset will be split into the number of child processes specified by -{cmd:parallel initialize}-
and the {mansection U 16Do-files:do-file} will be executed independently over
each and every one of the data chunks, so once after all the parallel-instances
stops, the datasets will be appended. In order to avoid loading the current
dataset in the child processes, the user should specify the -nodata- option.
{p_end}

{pstd}
-{cmd:parallel :}- (as a prefix) allows to, after splitting the loaded dataset,
execute a {it:stata_cmd} over the specified number of data chunks in order to
speed up computations. Like -{cmd:parallel do}-, after all the parallel-instances
stops, the datasets will be appended.
{p_end}

{pstd}
-{cmd:parallel bs}- and -{cmd:parallel sim}- are parallel wrappers for the commands
-{help bootstrap}- and -{help simulate}-. Specially suited for these algorithms,
-{cmd:parallel}- allows conducting embarrassingly parallel computing. In terms of
syntax, besides cmd names, the only difference that these two commands have with
their serial versions is how are {help exp_list:expressions} passed (please refer
to the {help parallel##examples:examples} section for this).
{p_end}

{pstd}
Every time that -{cmd:parallel}- runs several auxiliary files are generated which,
after finishing, are automatically deleted. In the case that the user sets -{opt keep}-
or -{opt keeplast}- the auxiliary files are kept, thus the syntax -{cmd:parallel clean}-
becomes handy. With -{cmd:parallel clean}- the user can remove the last generated
auxiliary files (default option), an specific parallel instance files (using
{it:#pll_id} number), or every stored auxiliary file (with -{opt all}-). For
security reasons, in-use auxiliary files will not be deleted unless the user
specifies it through the option {opt force}, which will override not deleting
in-use auxiliary files (see the {help parallel##tech:Technical note} section for
more information about this).
Log files from the runs are stored in {it:c(tmpdir)} so that they can be inspected by the user.
The user will likely want to delete these periodically with {cmd:parallel clean, all}.
{p_end}

{pstd}
In the case of handling multiple files (because it is, for example,
a big dataset divided into multiple dta files), -{cmd:parallel append}- becomes handy
as it allows the user to process them simultaneously. By providing a list of files
and a Stata cmd or dofile, -{cmd:parallel append}- opens and executes the cmd/dofile
within each file, stores each file results and appends them into a single file.
Also, if the files to be processed have a pattern base name, the user can provide
-{cmd:parallel append}- with an expression representing the list of files to be
processed; for information on how to use this feature, see the section
{help parallel##append_how:Parallel Append}.
{p_end}

{pstd}
Given {it:N} child processes, within each child process -{cmd:parallel}- creates the macros 
{it:pll_id} (equal for all the child processes) and {it:pll_instance} (ranging
1 up to {it:N}, equaling 1 inside the first child process and {it:N} inside the last child process), 
both as globals and locals macros. This allows the user setting different
tasks/actions depending on the child process. Also the global macro {it:PLL_CHILDREN}
(equal to {it:N}) is available within each child process. For an example using this
macros, please refer to the {help parallel##examples:Examples section}.
{p_end}

{pstd}
As by now, -{cmd:parallel}- by default automatically identifies Stata's
executable file path. This is necessary as it is used to run Stata in batch mode
(the mainstream of the module). Either way, after some reports, that file path is not
always correctly identified; where the option -{opt s:tatadir}- in -{cmd:parallel initialize}-
can be used to manually set it.
{p_end}

{pstd}
In the case of pseudo-random-numbers, the module allows to pass different seed for
each child process. Moreover, if the user does not provide a numlist of
seeds, -{cmd:parallel}- generates its own numlist of seeds using three different options:
(1) based on the current seed; (2) using the current datetime and user as a seed to
generate each seed, restoring the original seed afterwards; or
(3) using random.org API (requires internet connection) to directly generate each
seed (also restoring the original seed afterwards). -{cmd:parallel}- saves a macro
with the used seeds in the {cmd:r(pll_seeds)} macro.
{p_end}

{marker warnings}{...}
{pstd}
{err:WARNINGS} For each child process -{cmd:parallel}- starts a new Stata instance (thus
running as many processes as child processes), this way, should the user set more child processes
than cores the computer has, it is possible that the computer freezes.
{p_end}

{marker details}{...}
{title:3. Details}

{pstd}
Inspired by the R library ``snow'' and to be used in multicore CPUs
, -{cmd:parallel}- implements parallel computing methods through an OS's shell 
scripting (using Stata in batch mode) to speedup computations by splitting the
dataset into a determined number of child processes in such a way to implement a 
{browse "http://en.wikipedia.org/wiki/Data_parallelism":data parallelism} algorithm.
{p_end}

{pstd}
The number of efficient computing child processes depends upon the number of physical
cores (CPUs) with which your computer is built, e.g. if you have a quad-core
computer, the correct child process setting should be four. In the case of simultaneous
multithreading, such as that from
{browse "http://www.intel.com/content/www/us/en/architecture-and-technology/hyper-threading/hyper-threading-technology.html":Intel's hyper-threading technology (HTT)},
setting -{cmd:parallel}- following the number of processors threads, as it was expected,
hardly results into a perfect speedup scaling. In spite of it, after several tests
on HTT capable architectures, the results of implementing -{cmd:parallel}- according
to the machines physical cores versus its logical cores shows small though significant differences.
{p_end}

{pstd}
-{cmd:parallel}- is especially handy when it comes to implementing loop-based
simulation models (or simply loops), Stata commands such as reshape , or any job
that (a) can be repeated through data-blocks, and (b) routines that processes big
datasets (see the {help parallel##append_how:append section}). Furthermore, the commands
-{help parallel##bs:parallel bs}- and -{help parallel##sim:parallel sim}- are
specially designed to easily implement bootstrapping and (monte carlo) simulations
in parallel fashion.
{p_end}

{pstd}
At this time -{cmd:parallel}- has been successfully tested in Windows, Unix
and MacOS for Stata versions 11 to 14.
{p_end}

{pstd}
-{cmd:parallel}- does not change the RNG state (even if subcommands invoke randomization functions).
{p_end}

{pstd}
After several tests, it has been proven that--thanks to how -{cmd:parallel}- has been
written--it is possible to use the algorithm in such a way that other techniques
of parallel computing can be implemented; such as Monte Carlo Simulations, 
simultaneously running models, etc.. An extensive
example through Monte Carlo Simulations is provided
{browse "http://fmwww.bc.edu/repec/bocode/p/parallel.pdf":here}.
{p_end}

{pstd}
To distribute work across different machines in a computer cluster,
the machines need to be Linux/MacOS,
share a global file-system (e.g. NFS),
and have a non-interactive way to remotely execute commands. 
The most common way to remotely execute commands is to use {it:ssh} with
keyfiles so that no password is needed.
This is still a new feature, and synchronizing across machines in child processes can have odd corner cases, so users may encounter some trouble getting this to work.
{p_end}

{marker append_how}{...}
{title:4. Parallel Append}

{pstd}Imagine we have several dta files named -income.dta- stored in a set of folders
ranging 2008_01 up to 2012_12, this is, a total of 60 files (12 times 5) monthly ordered
which may look something like this: {p_end}

{col 10}{it:2008_01/income.dta}
{col 10}{it:2008_02/income.dta}
{col 10}{it:2008_03/income.dta}

{col 10}{it:...more files...}

{col 10}{it:2010_01/income.dta}
{col 10}{it:2010_02/income.dta}
{col 10}{it:2010_03/income.dta}

{col 10}{it:...more files...}

{col 10}{it:2012_10/income.dta}
{col 10}{it:2012_11/income.dta}
{col 10}{it:2012_12/income.dta}

{pstd}Now, imagine that for each and every one of those files we would like to
execute the following program:{p_end}

{tab}{cmd: program def myprogram}
{tab}{cmd:{tab} gen female = (gender == "female")}
{tab}{cmd:{tab} collapse (mean) income, by(female) fast}
{tab}{cmd: end}

{pstd}Instead of writing a forval/foreach loop (which would be the natural
solution for this situation), -{cmd:parallel append}- allows us to smoothly solve
this with the following command.{p_end}

{tab}{cmd:. parallel append, do(myprogram) prog(myprogram)} ///
{tab}{tab}{cmd:e("%g_%02.0f/income.dta, 2008/2012, 1/12")}

{pstd}Where element by element, we are telling parallel:{p_end}
{tab}(1) {cmd:do(myprogram)}: execute the command -{cmd:myprogram}-,
{tab}(2) {cmd:prog(myprogram)}: -{cmd:myprogram}- is a user written program, and
{tab}(3) {cmd:e("%g_%02.0f/income.dta, 2008/2012, 1/12")}: this should process files 2008_01/income.dta up to 2012_12/income.dta.

{pstd}Besides of the simplicity of its syntax, the advantage of using -{cmd:parallel append}-
lies in doing so in a parallel fashion, this is, instead of processing one file
at a time, -{cmd:parallel}- manages to process these files in groups of as
many files as child processes are set. Step-by-step, what this command does is:{p_end}

{p2colset 8 11 11 4}
{p2col:1.}Distribute groups of files across child processes{p_end}

{tab}Once each child process starts, for each dta file

{p2col:2.}Opens the file using {ifin} accordingly to {opt in} and {opt if} options.{p_end}
{p2col:3.}Executes the command/dofile specified by the user.{p_end}
{p2col:3.}Stores the results in a temp dta file.{p_end}

{tab}Finally, once all the files have been processed

{p2col:4.}Appends all the resulting files into a single one.{p_end}


{marker caveats}{...}
{title:5. Caveats}

{pstd}
When the -{it:stata_cmd}- or -{it:do-file}- {help saved_results:saves results},
as -{cmd:parallel}- runs Stata in {browse "http://www.stata.com/support/faqs/windows/batch-mode/":batch mode},
none of the results will be kept. This is also true for {help matrix:matrices},
{help scalar:scalars}, {help mata:mata objects}, {help return:returns}, or whatever
other object different from data.
{p_end}

{pstd}
Although -{cmd:parallel}- passes-through {help program list:programs}, {help macro:macros}
and {help mata:mata objects}, in the current version it is not capable of doing the same with
{help matrix:matrices} or {help scalar:scalars}.
The tempname internal state is copied to childre, but the parent does not receive any of this state from the children.
That is, -{cmd:parallel}- advances the tempname (tempvar) sequence in the children to not overlap with any produced by
the parent.
{p_end}
 
{pstd}
If the number of tasks to be done is less than the number of child processes, {cmd:parallel} will temporarily reduce
the number of child processes. This is reported in the global {cmd:$LAST_PLL_N}.
{p_end}
 
{pstd}
Expressions run in the child-processes that contain {it:_n} or {it:_N} will be evaluated locally to the child not the parent dataset.
These expressions may therefore be different if run in {cmd:parallel} than without {cmd:parallel}.
{p_end}
 
{pstd}
When executing Stata on separate machines via ssh, no environment variables except PWD and STATATMP are copied over.
{p_end}


{marker tech}{...}
{title:6. Technical note}

{pstd}
In order to protect a {it:pll_id} code (and thus ancillary files), once -{cmd:parallel}-
is called it creates a new file called {it:__pll}[{it:pll_id}]{it:sandbox} 
(stored at c(tmpdir), in your case: {ul:{ccl tmpdir}}). This
forbids -{cmd:parallel clean}- from deleting any auxiliary file used by that process
and reserves the {it:pll_id} so that no other call of -{cmd:parallel}- can
use this {it:pll_id}. Once every child process has finished, the sandbox file
is removed, freeing the {it:pll_id}.
{p_end}

{pstd}
If for any reason the algorithm breaks due to a flaw or crush of the system,
the sandbox file and the rest of auxiliary files will not be deleted. In order
to clean up this, the user will be able to do so manually (moving the file(s) to
the OS recycle bin) or using {help parallel#clean:parallel clean, all force}
syntax. This way all sandbox files in the c(tmpdir) folder and auxiliary files
stored at the current directory will be deleted.
{p_end}

{pstd}
In earlier versions of -{cmd:parallel}-, {help tempfile:tempfiles} generation was
not safe as while running multiple Stata instances simultaneously these could
overwrite each other's tempfiles. Starting version 1.14, this is no longer a
problem as each Stata instance starts with a different {cmd:c(tmpdir)} location.
This way, instances' tempfile management will not interfere with each other, allowing
to safely use commands or algorithms depending on tempfile generation (such as
{help preserve:preserve and restore}).
{p_end}

{pstd}
The option -{opt setparallelid}- is designed to let programmers recycle a
parallel id ({it:pll_id}). Intended to be used with -{cmd:parallel_sandbox}- 
(undocumented, please refer to the source code of 
-{help parallel_source##parallel_sandbox:parallel_sandbox()}-),
this option allows calling parallel several times using the same {it:pll_id}, which
makes auxiliary files management far simpler. Take the following example
{p_end}

{tab}{cmd: program def mypllwrapper}
{tab}{tab}{cmd:}
{tab}{tab}{it: // Reserving a pll_id}
{tab}{tab}{cmd: m: parallel_sandbox(5)}
{tab}{tab}{cmd:}
{tab}{tab}{it: // Using the generated pll_id}
{tab}{tab}{cmd: save __pll`parallelid'_mypllwrapper, replace}
{tab}{tab}{cmd:}
{tab}{tab}{it: // Recycling the pll_id}
{tab}{tab}{cmd: forval i=1/10 {c -(}}
{tab}{tab}{tab}{cmd: parallel, setparallelid(`parallelid') keep: some_other_cmd}
{tab}{tab}{cmd: {c )-}}
{tab}{tab}{cmd:}
{tab}{tab}{it: // Cleanning up and freeing the pll_id. This will remove all files}
{tab}{tab}{it: // and folders named with prefix '__pll[parallelid]'}
{tab}{tab}{cmd: parallel clean, e(`parallelid')}
{tab}{tab}{cmd: m: parallel_sandbox(2,"`parallelid'")}
{tab}{tab}{cmd:}
{tab}{cmd: end}

{pstd}
For a real example of this, please
see -{stata viewsource parallel_bs.ado:parallel.bs}- and 
-{stata viewsource parallel_sim.ado:parallel_sim.ado}-.
{p_end}

{title:Windows-shell: Spawning child processes with shell command on Windows (Deprecated)}

{pstd}
Originally child processes on Windows were spawned as they were on other platforms using Stata's shell methods (e.g. {cmd:winexec}). 
This had a number of problems (spawned processes stole the UI focus, failure to recover from killed child processes, difficulty in batch-mode), so now Windows uses a plugin that launches the child processes directly using Win32 system calls. 
The original functionality is retained, but deprecated. To enable it you must specified the {it:procexec(0)} option. {p_end}

{pstd}Since shell commmands are ignored by Stata in batch-mode on Windows, a work around is needed. The method is to have Stata write out the commands to be executed to a file
(called the gateway) and have a separate process read new inputs to this file and 
execute the commands. This latter part requires the user to install Cygwin and run 
a few commands prior to starting Stata. In a Cygwin terminal, navigate to the appropriate
directory and do the following:
{p_end}

{tab}{cmd:$ rm pll_gateway.sh}
{tab}{cmd:$ touch pll_gateway.sh}
{tab}{cmd:$ tail -f pll_gateway.sh | bash}

{pstd}Then you can execute your Stata script in batch-mode on Windows. The Cygwin tail
process can stay running through multiple uses.{p_end}

{pstd}The default gateway file assumed is pll_gateway.sh. If you would like a different
file modify the Cygwin script above and pass a new value for {opt g:ateway}({it:{help filename:gateway_path}}) to {cmd:parallel initialize}.{p_end}

{pstd}Since Cygwin is going to execute the commands to start the parallel Stata instances
it needs a Cygwin-like Stata path. If the user does not specify the Stata path then
-{cmd:parallel}- will take the generated windows path and convert it to "/cygdrive/<drive letter>/...".
If this does not work you will need to specify the {it:statapath} explicitly.{p_end}

{pstd}In this mode, there is no automatic way for the parent process to stop the child processes in case the user has requested a break in execution. 
The original (but now deprecated) {cmd:parallel break} can still be used (and mata equivalents {cmd:parallel_break()} and {cmd:_parallel_break()}). 
This is a call that is you write into the code that executes in the children that queries if the mother process has requested to break. 
If this is not used appropriately, and a child process is executing for a long period (e.g. an endless loop) the user must kill the child processes manually.{p_end}


{marker examples}{...}
{title:Example 1: using prefix syntax}

{pstd}In this example we'll generate a variable containing the maximum 
blood-pressure measurement ({it:bp}) by patient.{p_end}

{pstd}Setup for a quad-core computer{p_end}
{tab}{cmd:. sysuse bplong.dta}
{tab}{cmd:. sort patient}
	
{tab}{cmd:. parallel initialize 4}

{pstd}Computes the maximum of {it:bp} for each patient. We add the option {opt by(patient)}
to tell parallel not to split stories.{p_end}
{tab}{cmd:. parallel, by(patient): by patient: egen max_bp = max(bp)}
	
{pstd}Which is the ``parallel way'' to do:{p_end}

{tab}{cmd:. by patient: egen max_bp = max(bp)}
	
{pstd}Giving you the same result.{p_end}

	
{title: Example 2: using -{cmd:parallel do}- syntax}

{pstd}Another usage that may get big benefits from it is implementing loop-base
simulations. Imagine that we have a model that requires looping over each and
every record of a panel-data dataset.
{p_end}

{pstd}
Using -{cmd:parallel}-, the proper way to do this would be using the ``parallel do''
syntax
{p_end}

{tab}{cmd:. use mybigpanel.dta, clear}

{tab}{cmd:. parallel initialize 4}
{tab}{cmd:. parallel do mymodel.do}
	
{tab}{cmd:. collapse ...}

{pstd}where {it:mymodel.do} would look something like this{p_end}
	
{tab}{hline 35} begin of do-file {hline 12}
{tab}{tab}{cmd:local maxiter = _N}
{tab}{tab}{cmd:forval i = 1/`maxiter'} {cmd:{c -(}}
{tab}{tab}{tab}{it:...some routine...}
{tab}{tab}{cmd:{c )-}}
{tab}{hline 35} end of the do-file {hline 10}

{pstd}Or, in the case of using mata, this would look something like this{p_end}

{tab}{hline 35} begin of do-file {hline 12}
{tab}{tab}{cmd:mata:}
{tab}{tab}{cmd:N=c("N")}
{tab}{tab}{cmd:for(i = 1;i<=N;i++) {c -(}}
{tab}{tab}{tab}{it:...some routine...}
{tab}{tab}{cmd:{c )-}}
{tab}{hline 35} end of the do-file {hline 10}

{title:Example 3: setting the right path}

{pstd}In the case of -{cmd:parallel}- setting the stata.exe's path wrongly, using
-{cmd:setstatapath}- will correct the situation. So, if 
{it:"C:\Archivos de programa\Stata12/stata.exe"} is the right path we only have
to write:

{tab}{cmd:. parallel initialize 2, s("C:\Archivos de programa\Stata12/stata.exe")}


{title:Example 4: Using -{cmd:parallel bs}-}

{pstd}In this example we'll evaluate a regression model using bootstrapping{p_end}

{pstd}Setup for a quad-core computer{p_end}
{tab}{cmd:. sysuse auto, clear}
	
{tab}{cmd:. parallel initialize 4}

{pstd}Running parallel bs.{p_end}
{tab}{cmd:. parallel bs: reg price c.weig##c.weigh foreign rep}
	
{pstd}Which is the ``parallel way'' to do:{p_end}

{tab}{cmd:. bs: reg price c.weig##c.weigh foreign rep}


{title:Example 5: Using -{cmd:parallel sim}-}

{pstd}Example from {help simulate##examples:simulate}{p_end}

{pstd}Setup for a quad-core computer{p_end}
{tab}{cmd:. parallel initialize 4}

{pstd}Experiment that will be performed{p_end}
{tab}{cmd:program define lnsim, rclass}
{tab}{tab}{cmd:version {ccl stata_version}}
{tab}{tab}{cmd:syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]}
{tab}{tab}{cmd:drop _all}
{tab}{tab}{cmd:set obs `obs'}
{tab}{tab}{cmd:tempvar z}
{tab}{tab}{cmd:gen `z' = exp(rnormal(`mu',`sigma'))}
{tab}{tab}{cmd:summarize `z'}
{tab}{tab}{cmd:return scalar mean = r(mean)}
{tab}{tab}{cmd:return scalar Var  = r(Var)}
{tab}{cmd:end}

{pstd}Running parallel sim.{p_end}
{tab}{cmd:. parallel sim, expr(mean=r(mean) var=r(Var)) reps(10000): lnsim, obs(100)}
	
{pstd}Which is the ``parallel way'' to do:{p_end}

{tab}{cmd:. simulate mean=r(mean) var=r(Var), reps(10000): lnsim, obs(100)}


{title:Example 6: Using -pll_instance- and -PLL_CHILDREN- macros}

{pstd}
By using -pll_instance- and -PLL_CHILDREN- global macros the
user can run -{cmd:parallel}- in such a way that each child process performs a different
task. Take the following example:
{p_end}

{pstd}Setup for a quad-core computer{p_end}
{tab}{cmd:. parallel initialize 4}
{tab}{cmd:. sysuse auto, clear}

{tab}{cmd:program def myprog}
{tab}{tab}{cmd:gen x = $pll_instance}
{tab}{tab}{cmd:gen y = $PLL_CHILDREN}
	
{tab}{tab}{it:// For the first child process}
{tab}{tab}{cmd:if ($pll_instance == 1) gen z = exp(2)}
	
{tab}{tab}{it:// For the second child process}
{tab}{tab}{cmd:else if ($pll_instance == 2) {c -(}}
{tab}{tab}{tab}{cmd:summ price}
{tab}{tab}{tab}{cmd:gen z = r(mean)}
{tab}{tab}{cmd:{c )-}}
	
{tab}{tab}{cmd:// For the third and fourth child processes}
{tab}{tab}{cmd:else gen z = 0}
{tab}{cmd:end}

{pstd}Running the program{p_end}
{tab}{cmd:. parallel, prog(myprog): myprog}

{pstd}
Here, running with 4 cores, the program -{cmd:myprog}- performs different actions
depending on the value (number) of -pll_instance-. For those observation in the
first child process, -{cmd:parallel}- will generate -z- equal to exp(2), for those in 
the second child process it will compute -z- equal to the average price and for the
rest of the child processes it will generate -z- equal to zero.
{p_end}

{marker saved_results}{...}
{title:8. Saved results}

{pstd}
-{cmd:parallel}- saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(pll_n)}}Number of parallel child processes last used{p_end}
{synopt:{cmd:r(pll_t_fini)}}Time took to appending and cleaning{p_end}
{synopt:{cmd:r(pll_t_calc)}}Time took to complete the parallel job{p_end}
{synopt:{cmd:r(pll_t_setu)}}Time took to setup (before the parallelization) and to finish the job (after the parallelization){p_end}
{synopt:{cmd:r(pll_errs)}}Number of child processes which stopped with an error.{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(pll_id)}}Id of the last parallel instance executed (needed to use {cmd:parallel clean}){p_end}
{synopt:{cmd:r(pll_dir)}}Directory where parallel ran and stored the auxiliary files.{p_end}
{synopt:{cmd:r(pll_seeds)}}Seeds used within each child process.{p_end}


{pstd}
-{cmd:parallel bs}- and -{cmd:parallel sim}- save the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:e(pll)}}1.{p_end}


{pstd}
-{cmd:parallel version}- saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Macros}{p_end}
{synopt:{cmd:r(pll_vers)}}Current version of the module.{p_end}

{pstd}
-{cmd:parallel numprocessors}- saves the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Scalars}{p_end}
{synopt:{cmd:r(numprocessors)}}Number of logical processors on the system.{p_end}


{pstd}-{cmd:parallel}- saves the following global macros:{p_end}

{synoptset 20 tabbed}{...}
{synopt:{cmd:$LAST_PLL_DIR}}A copy of {cmd:r(pll_dir)}.{p_end}
{synopt:{cmd:$LAST_PLL_N}}A copy of {cmd:r(pll_n)}.{p_end}
{synopt:{cmd:$LAST_PLL_ID}}A copy of {cmd:r(pll_id)}.{p_end}
{synopt:{cmd:$PLL_LASTRNG}}Number of times that -{cmd:parallel_randomid()}- has
been executed.{p_end}
{synopt:{cmd:$PLL_STATA_PATH, $PLL_CLUSTERS (deprecated), $PLL_CHILDREN, $USE_PROCEXEC, $PLL_HOSTNAMES, $PLL_SSH}}Internal usage.{p_end}


{marker development}{...}
{title:9. Development}

{pstd}
You can always have access to the latest version of -{cmd:parallel}-. One option
is from its github repo (on-development source code):
{p_end}

{pmore}{browse "https://github.com/gvegayon/parallel"}{p_end}

{pstd} Or from the project's website:{p_end}

	{cmd:. net install parallel, from(https://raw.github.com/gvegayon/parallel/master/) replace}
	{cmd:. mata mata mlib index}


{pstd}
You can track new releases on GitHub or by following the RSS feed https://github.com/gvegayon/parallel/releases.atom
{p_end}


{pstd}
In the case of bug reporting, you can submit issues here:
{p_end}

{pmore}{browse "https://github.com/gvegayon/parallel/issues"}

{pstd}
Please try the latest version to see if your problem has been solved.
Include the steps to reproduce the issue and the output of the Stata
command -creturn list-.
{p_end}


{marker source}{...}
{title:10. {cmd:mata} source code}

{pstd}
Most of -{cmd:parallel}- has been programmed in {cmd:mata}. This means that, as a difference
from typical ado files, -{cmd:parallel}- is distributed with {cmd:lparallel} mata library
(compiled code) and thus source code can not be reached directly by users. Given
this, the help file {cmd:{help parallel_source:parallel_source.sthlp}} is included
in the package, help file which contains the source code in a fancy way.

{pstd}
In order to get access to different sections of the source code you can follow these
links:
		
        Stops a child process after the user pressed break {col 58} {help parallel_source##parallel_break:parallel_break.mata}
        Remove auxiliary files {col 58} {help parallel_source##parallel_clean:parallel_clean.mata}
        Distributes observations across child processes {col 58} {help parallel_source##parallel_divide_index:parallel_divide_index.mata}
        Export global macros {col 58} {help parallel_source##parallel_export_globals:parallel_export_globals.mata}
        Export programs {col 58} {help parallel_source##parallel_export_programs:parallel_export_programs.mata}
        Wait until a child process finishes {col 58} {help parallel_source##parallel_finito:parallel_finito.mata}
        (on development) {col 58} {help parallel_source##parallel_for:parallel_for.mata}
        Normalize a filepath {col 58} {help parallel_source##parallel_normalizepath:parallel_normalizepath.mata}
        Generate random alphanum {col 58} {help parallel_source##parallel_randomid:parallel_randomid.mata}
        Lunch simultaneous Stata instances in batch mode {col 58} {help parallel_source##parallel_run:parallel_run.mata}
        Set of tools to protect parallel aux files {col 58} {help parallel_source##parallel_sandbox:parallel_sandbox.mata}
        Set the number of child processes {col 58} {help parallel_source##parallel_initialize:parallel_initialize.mata}
        Set the Stata EXE directory {col 58} {help parallel_source##parallel_setstatapath:parallel_setstatapath.mata}
        Write a ``diagnosis'' {col 58} {help parallel_source##parallel_write_diagnosis:parallel_write_diagnosis.mata}
        Write a dofile to be paralellized {col 58} {help parallel_source##parallel_write_do:parallel_write_do.mata}

{marker references}{...}

{title:11. References}

{phang}Luke Tierney, A. J. Rossini, Na Li and H. Sevcikova (2012). {it:snow: Simple Network of Workstations}. R package version 0.3-9. {browse "http://CRAN.R-project.org/package=snow"}{p_end}
{phang}R Core Team (2012). {it:R: A language and environment for statistical computing}. R Foundation for Statistical Computing, Vienna, Austria. ISBN 3-900051-07-0, URL {browse "http://www.R-project.org/"}.{p_end}
{phang}George Vega Y (2012). {it:Introducing PARALLEL: Stata Module for Parallel Computing}. Chilean Pension Supervisor, Santiago de Chile, URL {browse "http://fmwww.bc.edu/repec/bocode/p/parallel.pdf"}.{p_end}
{phang}George Vega Y (2013). {it:Introducing PARALLEL: Stata Module for Parallel Computing}. Stata Conference 2013, New Orleans (USA), URL {browse "http://ideas.repec.org/p/boc/norl13/4.html"}.{p_end}
{phang}Haahr, M. (2006). {it:Random.org: True random number service}. Random.org. {browse "http://www.random.org/clients/http/"}.{p_end}


{marker authors}{...}
{title:12. Authors}

{pstd}
George Vega Yon [cre,aut], University of Southern California. {browse "mailto:g.vegayon@gmail.com"}
{browse "http://ggvy.cl/"}
{p_end}

{pstd}
Brian Quistorff [aut], Microsoft Research. {browse "mailto:Brian.Quistorff@microsoft.com"} {browse "http://quistorff.com"}
{p_end}

{marker contrib}{...}
{title:13. Contributors}

{pstd}{it:Special Thanks to:}
Elan P. Kugelmass (aka as epkugelmass at github) [ctb],
Timothy Mak (University of Hong Kong) (author of {net "describe miparallel, from(http://fmwww.bc.edu/RePEc/bocode/m)":miparallel})
{p_end}

{pstd}
Damian C. Clarke (Oxford University, England), 
Felix Villatoro (Superintendencia de Pensiones, Chile),
Eduardo Fajnzylber (Universidad Adolfo Ib{c a'}{c n~}ez, Chile), 
Eric Melse (CAREM, Netherlands),
Tom{c a'}s Rau (Universidad Cat{c o'}lica, Chile), 
Research Division (Superindentendia de Pensiones, Chile), 
attendees to the Stata conference 2013 (New Orleans),
Philippe Ruh (University of Zurich), 
Michael Lacy (Colorado State).
{p_end}


{marker also}{...}
{title:14. Also see}

{psee}
Manual: {mansection "GSM CAdvancedStatausage":{bf:[GSM] Advanced Stata usage (Mac)}},
        {mansection "GSU CAdvancedStatausage":{bf:[GSU] Advanced Stata usage (Unix)}},
        {mansection "GSW CAdvancedStatausage":{bf:[GSW] Advanced Stata usage (Windows)}}

		
{psee}
Online: Running Stata batch-mode in {browse "http://www.stata.com/support/faqs/mac/advanced-topics/#batch": Mac},
{browse "http://www.stata.com/support/faqs/unix/batch-mode/":Unix} and 
{browse "http://www.stata.com/support/faqs/windows/batch-mode/":Windows}
{p_end}

{psee}
Project's wiki {browse "https://github.com/gvegayon/parallel/wiki/Gallery":page of other examples}.
{p_end}


{marker faqs}{...}
{title:15. FAQs}

{pstd}
Here follows a list of Frequently Asked Questions:{p_end}

{p2colset 6 10 10 2}
{p2col: 1.}{bf:I am getting error (608) {err: file is read-only; cannot be modified or erased}. What can I do to solve it?}{p_end}

{p2col:}As Stata suggests, you are trying to either run parallel in a read-only
directory, or your program/dofile is trying to write (save a dta file for
example) in a read-only directory. Try running parallel (or making your program to
write files) in a directory where you have writing priviledges (where you can
save files).
{p_end}

{p2col: 2.} {p_end}


