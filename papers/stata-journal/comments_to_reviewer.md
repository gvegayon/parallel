The quoted sections (>) are the reviewer comments and we've bulleted (*) our responses.

> It would probably be useful to define "socket" for users who are not as familiar with these concepts.  It could also be useful to reference either processors or cores to avoid any potential confusion among readers.  It would be useful to provide some type of context/explanation of what types of tasks might be considered "embarrassingly parallel" and to provide a bit of context around  what types of tasks make good candidates for parallelization.  The first paragraph is fine for readers who are already familiar with this topic area to some degree, but I think providing a bit more context initially could make the opening  more appealing to the broader readership of the Stata Journal.  In the last sentence the 'to parallelize these tasks' is vague.  If you're able to  provide some context around tasks that don't require communication between themselves I think it will clarify the meaning/intent of this sentence quite a bit.  The citation refering to Stata's performance report lists  a different year from the website that it references : 30jan2016 Superscripts in the paragraph below redirect users to the wrong location in  the document (both direct users to the figure on the following page).

*   We simplified this paragraph by removing the part mentioning sockets and cores, and just talking about processors (cores) and leave it there.

*   We gave examples of embarassingly parallel tasks

*   We've updated the reference and links.

> Perhaps providing information about the difference between distributed and shared memory parallelization prior to referring to it will help other readers follow your points more effectively?

*   Done
    
> I would try to stick with referring to child processes instead of clusters here.  There is a risk that some readers might start to think about cluster computing when it seems like your intent is to refer to the number of spawned tasks.  I'd change the structure of the second sentence a bit to clarify things a bit: Second, \texttt{parallel} will use more memory (i.e. RAM) to process a task.  Rather than only stating there would be little benefit of using parallel with data that consumes a non-trivial amount of memory, it might be good to provide a few words about what could happen in the case that someone did try to use parallel with a large data set (e.g., paging, potential for memory corruption, etc...).  It would also be useful to warn users that while their data set may not consume  the vast majority of the available physical memory, there are computational tasks  that could consume non trivial amounts of memory for completion (e.g., matrix operations).

*   Switched article and package to use "child process" rather than "cluster". Resulted in minor change to API (with backwards compatibility)

*   Re memory: Done
    
    
> Stata/MP is a flavor (assuming StataCorps is still using that verbiage).  Please add the appropriate citations for the parallel & snow packages as well as the Matlab reference.

*   Done
    
> I'm not sure you need this paragraph.  It isn't bad, but the transition between introducing this roadmap and then introducing another road map immediately after the next section heading seems too lose momentum.

*   Removed and just introduced the next section.

> Perhaps add a reference to when you will discuss the diagnostic tool commands.

*   Reorganized this so they are mentioned in order of the subsections.

> I think it might be useful to align the program and article semantically.  If the subcommand is setclusters it might be better to not use the parent/child node reference as strongly and to use some other expression so you can reference clusters in the prose and in the program.

*   Done as part of broader cleanup to move from cluster->child process.
    
> Purely as a lazy/style thing, why not make the numeric value optional and implement the default in the case where an end user does not provide a value?  Perhaps you are trying to subtly force the user to define the number of instances to spawn by saving them key strokes to enter the integer, but it seems a bit odd to require the user to type default as opposed to using an optional integer value.  It might also be good to provide a note about whether or not the processors option is intended for physical, virtual, and/or logical cores.

*   Added blank default.
    
> What is meant by slowdowns?  Is this related to potential paging of memory or due to processor limits?

*   Clarified about context switching programs.

> Since the Stata path is stored in `c(sysdir_stata)', is the purpose for this to allow users to point at different versions of Stata that would be launched from the master process?  It might be useful to provide some type of example (even hypothetical) to illustrate the use case for this option.

*   We have seen in the past that the stata path is not there... and it can sometimes be different for mac os. Clarified.


> Why would end users use this subcommand versus : di c(processors)?  It might be more useful if there was a command that returned something  analogous to a configuration file that users could call to get more information than they would by just displaying creturn values.  

*   Only on Stata/MP can you query this (with c(processors_mach))

> It seems like parallel is based on row-wise operations.  What if a user wanted to parallelize execution over the columns (e.g., variables)?  The use case that I am  thinking about here is data cleaning where someone may want to implement the same set of code to clean many variables.  Rather than looping over the variable names, would it be possible to parallelize the operations over the columns instead of the rows in the data object?

*   This is technically possible, but currently difficult. We will add it to the wish list.

*   Added a short paragrpah of the API

> I think it could be useful to discuss why the programs and mata objects get handled this way.  I'm not exactly sure why the program names would need to be passed in the manner specified below (assuming those programs are found on the user's ADOPATH.  If this is more intended to reference something defined in the local directory, it would definitely be helpful to clarify that since it could have some fairly bizarre effects if a user calls one program that has dependencies on several others that they are unaware of. The Mata issue seems a bit more problematic since I imagine there are a fair number of mata libraries that make use of pointers in their functions/objects.  It might be good to connect with some of the folks at Stata to see what happens when a single machine runs multiple instances of Stata and each instance has access to the same Mata libraries and calls some function that uses pointers in both instances.  

*   Clarified that this is for local programs that are available only on the current instance of stata (not in ADOPATH). Mata functions work, but mata variables that are pointers won't.

> I do think that being able to use random.org is a pretty cool feature of the program.

*   Thanks!

> Given how different the semantics of the expression option below looks, it might be useful to include some simple hypothetical example to illustrate how/what the expansion of the expression would look like and do.

*   Mentioned the example below.

> What is the default behavior when a user does not pass any values to any of the optional parameters? Also, it would be useful to define what you mean by event.  Does event mean a spawned process, an individual command within a do file, or something else?

*   Clarified

> See the note above about defining the term event.  This part of the information gets a bit difficult to understand precisely what you are trying to convey.

*   Clarified

> See the note above about defining the term event.  This part of the information gets a bit difficult to understand precisely what you are trying to convey.

> What is it that is saved in e(pll)?

*   We check whether the sim or bs was parallel or not for replay. I've marked it as "internal".

> I cannot express the look on my face reading the last few sentences sufficiently enough, but know that my response was wholeheartedly positive. Is there potentially some way to use the OS to suppress launching the GUI or to potentially launch the GUI with the application forced into the background or minimized? As an additional note, I attempted running the examples on a machine running Windows 10 and did not notice any screen flashing or anything like that.  However, there were some other errors when I attempted running things.  I'll try  running the examples again once I'm in the office, but am connected to a physical machine using Remote Desktop Connection at the moment.

*   Yes, we use the Win32 mechanism to launch the child processes in a hidden desktop.

> How would this potentially effect estimation commands if matrices are not available once the child process finishes the execution of the commands?

*   One's not able to use it with regression. You can always store things explicitly. Noted.

> If you want to provide instructions for this you can use:
\begin{lstlisting}
  . ado, find(parallel)
  . ado uninstall [#] 
\end{lstlisting}
This will probably return more results than they would hope, but it at least could illustrate how they would uninstall things.

* Added a simple command example to this effect.

> Make sure to let the users know that if they are trying to follow the examples here sequentially they will need to drop  the price2 variable first.

*   Done

> This example failed to execute properly.  I've saved the error log so it could be sent back to you and can add an issue in GitHub.

*   We were able to run this example. Please provide further information.

> It would be useful to include some simple example files that could be used to test/verify this subcommand/functionality.

*   We have a test suite on the GitHub repo. We test this functionality using 'test files/test_append.do'

> It isn't clear how this would affect loops that exist within community/user contributed/developed commands.  Is there some recommended refactoring that others could implement that would allow the internals of their program to take advantage of parallel when the loops exist within the main body of the user/community defined command? 

*   "As shown 3.2",

> Does parallel have any performance effect on programs and/or scripts that generate a non-trivial number of graphs?  Do the simulation/bootstrap results depend on the algorithm used to estimate the model parameters (e.g., iterative vs non iterative algorithms)?  What about models that are a bit more complex?  It might be useful to use some of the existing Stata examples that take a bit longer to execute as points of comparison (particularly if you can compare the single processor execution with MP execution on a comparable number of cores).  It might also be useful to run the same benchmarks with later versions of Stata in case the commands used have been further optimized.  One potentially useful point of comparison could be to use some of the models presented in McCoach et al. (2018); I've added this citation to your BibTex file in case you are interested in that as a reference.  In particular, the article shows how Stata is orders of magnitude slower at fitting mixed effects models compared to R, HLM, and Mplus.  Using one of the examples McCoach et al used could make a more immediate contribution to the literature as a whole and provide some benchmarking compared to other published/existing studies involving the runtime performance of Stata.

*   We are focused on data analysis, so we don't know about work loads with large numbers of graphs. If the simulations/bootstraps/models are independent then you should see a speed-up no matter the internal algorithm (again with the proviso about using too much memory). A detailed comparison or the speedups across functions would be very useful, though it will be very depedent on setting (data size, processors, memory) and we think beyond the scope of this paper.

> Similarly, someone recently gave a talk at Juliacon 2018 about performance benchmarks between Julia, Stata, R, and maybe Python (can't remember if Python was included in the talk or not).  You can find the abstract for that talk here: http://juliacon.org/2018/talks_workshops/110/ In the talk, the authors of -gsreg- had ported their command to the Julia language and run benchmarks of the command and/or comparable command in the languages mentioned above.  Again, in this instance Stata had the worst runtime performance of the languages.  Creating the benchmarks with similar examples could also provide a more contextualized benchmarking suite.

*   That is a nice idea. Perhaps in the future we could try to build something like that. The problem is that, since we are already looking at embarasignly parallelizable tasks, most other languages have that, so the comparison is trivial.

> It would probably be good to put the project website in parentheses so interested readers can go directly to the site instead of searching for it.

*   Done

> This example will fail because the global $size is not defined prior to being  referenced in the example.

*   Fixed.

> I think the second row in the table may be more confusing than helpful. Rather than displaying performance relative to the four core performance in the table, it might be easier to discuss it in the prose.  This would also provide the added flexibility of discussing relative performance gains for the case of the serial vs 2 core and 2 vs 4 core trials.  Additionally, it might be helpful to create a box plot for the different conditions to show the runtime variances and identify if there were any outliers (e.g., perhaps the load on the physical server increased and some resources on the Unix server were being reallocated in some of the runs, or maybe other issues cropped up that are interesting).  It'd be interesting to see if the variance in runtimes were relatively stable as well and to see if the variance in the runtime was comparable across all conditions.  It isn't completely necessary, but you could also fit an ANOVA to your benchmark data to further support the performance benchmark claims.

*   We removed the relative unit row. There's low variance on the compute times and the variance would be likely more telling of a particular environment rather than general usage. For similar reasons we think the ANOVA wouldn't add much.

> If the simulation is uninteresting why would it be important to others?  If it is easy enough to program a simulation that others might find more compelling that might be more useful for multiple reasons.  If it isn't, I would leave out the uninteresting comment to avoid selling your work short.

*    Removed "uninteresting" as it is more appropriately just simple.

> Unrelated to the article itself, but if you've not already set up templates for pull-requests and issues it would probably be useful to do that.  Even though you are explaining what information you'd like to receive in the issue body, I suspect you'll have instances where users forget to include reproducible examples in the issue body.  Setting up the templates would help to prevent this from happening and would also make it cleaner/easier to read the initial issue that comes in.  Feel free to reach out if you need any help with this.

* Thanks, we do have a template!

> I think the conclusion is nice, short, and too the point.  However, I think it might be useful to provide an example that better illustrates how community contributors could integrate parallel with the programs they are developing.  The sequential consistency example doesn't make it clear how a community contributor would make use of parallel internally in a program.  You could also potentially add this as a wiki page for the package and direct readers to the wiki page/project page to find a fleshed out example of how you would suggest others integrate parallel within their packages.

*   Mentioned the wiki page.
