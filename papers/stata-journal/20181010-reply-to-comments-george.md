> It would probably be useful to define "socket" for users who are not as familiar with these concepts.  It could also be useful to reference either processors or cores to avoid any potential confusion among readers.  It would be useful to provide some type of context/explanation of what types of tasks might be considered "embarrassingly parallel" and to provide a bit of context around  what types of tasks make good candidates for parallelization.  The first paragraph is fine for readers who are already familiar with this topic area to some degree, but I think providing a bit more context initially could make the opening  more appealing to the broader readership of the Stata Journal.  In the last sentence the 'to parallelize these tasks' is vague.  If you're able to  provide some context around tasks that don't require communication between themselves I think it will clarify the meaning/intent of this sentence quite a bit.  The citation refering to Stata's performance report lists  a different year from the website that it references : 30jan2016 Superscripts in the paragraph below redirect users to the wrong location in  the document (both direct users to the figure on the following page).

*   Perhaps we could simplify this paragraph by removing all the part mentioning
    sockets and cores, and just talk about processors (cores) and leave it there.

*   "for example, bootstrapping/jacknife, Monte carlo simulations, reshaping a dataset, etc."

*   Thank you for the comments on the reference and links.

> Perhaps providing information about the difference between distributed and shared
memory parallelization prior to referring to it will help other readers follow your
points more effectively?

*   Sure, we could said something like: "The way parallel works is essentially creating
    multiple stata instances in which each one of these has its own copy of whatever
    data it is supposed to work with."
    
> I would try to stick with referring to child processes instead of clusters here.  There is a risk that some readers might start to think about cluster computing when it seems like your intent is to refer to the number of spawned tasks.  I'd change the structure of the second sentence a bit to clarify things a bit: Second, \texttt{parallel} will use more memory (i.e. RAM) to process a task.  Rather than only stating there would be little benefit of using parallel with data that consumes a non-trivial amount of memory, it might be good to provide a few words about what could happen in the case that someone did try to use parallel with a large data set (e.g., paging, potential for memory corruption, etc...).  It would also be useful to warn users that while their data set may not consume  the vast majority of the available physical memory, there are computational tasks  that could consume non trivial amounts of memory for completion (e.g., matrix operations).

*   Agree with the child process

*   Good point about memory. We could say "in the simplest case, when splitting
    the data, the spawned processes' memory will add up to the same amount of
    memory used in the current session. And to this add the amount of memory that
    Stata uses while doing some operations such as matrix invertion.".
    
    
> Stata/MP is a flavor (assuming StataCorps is still using that verbiage).  Please add the appropriate citations for the parallel & snow packages as well as the Matlab reference.

*   OK
    
> I'm not sure you need this paragraph.  It isn't bad, but the transition between introducing this roadmap and then introducing another road map immediately after the next section heading seems too lose momentum.

*   We can get rid of it and just introduce the next section.

> Perhaps add a reference to when you will discuss the diagnostic tool commands.

*   Not sure about this comment.

> I think it might be useful to align the program and article semantically.  If the subcommand is setclusters it might be better to not use the parent/child node reference as strongly and to use some other expression so you can reference clusters in the prose and in the program.

*   This is a tricky one... perhaps we could start moving away from cluster and
    to threads actually, which is more appropiate.
    
> Purely as a lazy/style thing, why not make the numeric value optional and implement the default in the case where an end user does not provide a value?  Perhaps you are trying to subtly force the user to define the number of instances to spawn by saving them key strokes to enter the integer, but it seems a bit odd to require the user to type default as opposed to using an optional integer value.  It might also be good to provide a note about whether or not the processors option is intended for physical, virtual, and/or logical cores.

*   I do disagree with this part. It is important that user is at least aware of
    how many processes he/she is using. Don't know what to do with this.
    
> What is meant by slowdowns?  Is this related to potential paging of memory or due to processor limits?

*   I think this may apply to multithreaded. But more than that, right now to the hard threshold of 8.

> Since the Stata path is stored in `c(sysdir_stata)', is the purpose for this to allow users to point at different versions of Stata that would be launched from the master process?  It might be useful to provide some type of example (even hypothetical) to illustrate the use case for this option.

*   Kind of, we have seen in the past that the stata path is not there... and it
    can be different for mac os. On different system this is reported differntly


> Why would end users use this subcommand versus : di c(processors)?  It might be more useful if there was a command that returned something  analogous to a configuration file that users could call to get more information than they would by just displaying creturn values.  

*   Not sure, Brian? Not necessarily, in my case shows 1 when I have 4.

> It seems like parallel is based on row-wise operations.  What if a user wanted to parallelize execution over the columns (e.g., variables)?  The use case that I am  thinking about here is data cleaning where someone may want to implement the same set of code to clean many variables.  Rather than looping over the variable names, would it be possible to parallelize the operations over the columns instead of the rows in the data object?

*   Sure, you can create your own implementation of parallel that does that. We will add it to the wish list.

*   Add a short paragrpah of the API

> I think it could be useful to discuss why the programs and mata objects get handled this way.  I'm not exactly sure why the program names would need to be passed in the manner specified below (assuming those programs are found on the user's ADOPATH.  If this is more intended to reference something defined in the local directory, it would definitely be helpful to clarify that since it could have some fairly bizarre effects if a user calls one program that has dependencies on several others that they are unaware of. The Mata issue seems a bit more problematic since I imagine there are a fair number of mata libraries that make use of pointers in their functions/objects.  It might be good to connect with some of the folks at Stata to see what happens when a single machine runs multiple instances of Stata and each instance has access to the same Mata libraries and calls some function that uses pointers in both instances.  

*   This is for local programs that are available only on the current instance of stata. Mata functions work, but mata variables that are pointers won't.

> I do think that being able to use random.org is a pretty cool feature of the program.

*   Thanks!

> Given how different the semantics of the expression option below looks, it might be useful to include some simple hypothetical example to illustrate how/what the expansion of the expression would look like and do.

*   We do have that. "See section asdasdad"

> What is the default behavior when a user does not pass any values to any of the optional parameters? Also, it would be useful to define what you mean by event.  Does event mean a spawned process, an individual command within a do file, or something else?


*   It's right there., right?

> See the note above about defining the term event.  This part of the information gets a bit difficult to understand precisely what you are trying to convey.

*   An event is an execution of a parallel task.

> See the note above about defining the term event.  This part of the information gets a bit difficult to understand precisely what you are trying to convey.

> What is it that is saved in e(pll)?

*   We check whether the sim or bs was parallel or not for replay.

*   It will remove the latest.

> I cannot express the look on my face reading the last few sentences sufficiently enough, but know that my response was wholeheartedly positive. Is there potentially some way to use the OS to suppress launching the GUI or to potentially launch the GUI with the application forced into the background or minimized? As an additional note, I attempted running the examples on a machine running Windows 10 and did not notice any screen flashing or anything like that.  However, there were some other errors when I attempted running things.  I'll try  running the examples again once I'm in the office, but am connected to a physical machine using Remote Desktop Connection at the moment.

*   Brian.

> How would this potentially effect estimation commands if matrices are not available once the child process finishes the execution of the commands?

*   Not able to use with regression. You can always store things explicitly.

> If you want to provide instructions for this you can use:
\begin{lstlisting}
  . ado, find(parallel)
  . ado uninstall [#] 
\end{lstlisting}
This will probably return more results than they would hope, but it at least could illustrate how they would uninstall things.

> Make sure to let the users know that if they are trying to follow the examples here sequentially they will need to drop  the price2 variable first.

*   Fit it

> This example failed to execute properly.  I've saved the error log so it could be sent back to you and can add an issue in GitHub.

*   Check

> It would be useful to include some simple example files that could be used to test/verify this subcommand/functionality.

*   Can we refere it.

*   parallel run tests

> It isn't clear how this would affect loops that exist within community/user contributed/developed commands.  Is there some recommended refactoring that others could implement that would allow the internals of their program to take advantage of parallel when the loops exist within the main body of the user/community defined command? 

*   "As shown 3.2",

> Does parallel have any performance effect on programs and/or scripts that generate a non-trivial number of graphs?  Do the simulation/bootstrap results depend on the algorithm used to estimate the model parameters (e.g., iterative vs non iterative algorithms)?  What about models that are a bit more complex?  It might be useful to use some of the existing Stata examples that take a bit longer to execute as points of comparison (particularly if you can compare the single processor execution with MP execution on a comparable number of cores).  It might also be useful to run the same benchmarks with later versions of Stata in case the commands used have been further optimized.  One potentially useful point of comparison could be to use some of the models presented in McCoach et al. (2018); I've added this citation to your BibTex file in case you are interested in that as a reference.  In particular, the article shows how Stata is orders of magnitude slower at fitting mixed effects models compared to R, HLM, and Mplus.  Using one of the examples McCoach et al used could make a more immediate contribution to the literature as a whole and provide some benchmarking compared to other published/existing studies involving the runtime performance of Stata.

*   We are focused on data analysis. 

*   See example of sequential consistency. What could drive differences between serial and parallel.

*   McCoach et al. (2018): Minimum amount of benchmarking.

> Similarly, someone recently gave a talk at Juliacon 2018 about performance benchmarks between Julia, Stata, R, and maybe Python (can't remember if Python was included in the talk or not).  You can find the abstract for that talk here: http://juliacon.org/2018/talks_workshops/110/ In the talk, the authors of -gsreg- had ported their command to the Julia language and run benchmarks of the command and/or comparable command in the languages mentioned above.  Again, in this instance Stata had the worst runtime performance of the languages.  Creating the benchmarks with similar examples could also provide a more contextualized benchmarking suite.

> It would probably be good to put the project website in parentheses so interested readers can go directly to the site instead of searching for it.

*   Put the project website.

> This example will fail because the global $size is not defined prior to being  referenced in the example.

*   Good catch.

> I think the second row in the table may be more confusing than helpful. Rather than displaying performance relative to the four core performance in the table, it might be easier to discuss it in the prose.  This would also provide the added flexibility of discussing relative performance gains for the case of the serial vs 2 core and 2 vs 4 core trials.  Additionally, it might be helpful to create a box plot for the different conditions to show the runtime variances and identify if there were any outliers (e.g., perhaps the load on the physical server increased and some resources on the Unix server were being reallocated in some of the runs, or maybe other issues cropped up that are interesting).  It'd be interesting to see if the variance in runtimes were relatively stable as well and to see if the variance in the runtime was comparable across all conditions.  It isn't completely necessary, but you could also fit an ANOVA to your benchmark data to further support the performance benchmark claims.

*   Perhaps we can have a graph for that...

*   There's low variance on thecompute times.

> If the simulation is uninteresting why would it be important to others?  If it is easy enough to program a simulation that others might find more compelling that might be more useful for multiple reasons.  If it isn't, I would leave out the uninteresting comment to avoid selling your work short.

*    OK, remove it

> I think the conclusion is nice, short, and too the point.  However, I think it might be useful to provide an example that better illustrates how community contributors could integrate parallel with the programs they are developing.  The sequential consistency example doesn't make it clear how a community contributor would make use of parallel internally in a program.  You could also potentially add this as a wiki page for the package and direct readers to the wiki page/project page to find a fleshed out example of how you would suggest others integrate parallel within their packages.

*   Mention the programs and wiki page.
