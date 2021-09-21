{smcl}
{* *! version 1.20.1 09sep2021}{...}
{vieweralsosee "parallel" "help parallel"}{...}
{cmd:help bshell}
{hline}

{title:Title}

{phang}
{bf:bshell} {hline 2} Stata module to run shell processes in all platforms and modes.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:bshell} {it:command}

{marker description}{...}
{title:Description}

{pstd}
This is a drop-in replacement for {cmd:shell} that works on all platforms and modes.
Normally it just passes the {it:command} on to {cmd:shell}. But in batch-mode on Windows {cmd:shell} doesn't work 
(commands are ignored) and so in these cases we use a compiled plugin to launch the process using win32 API.
If you need to invoke {cmd:cmd} (for example to handle redirections), 
you can call {cmd:bshell cmd /c ...}, though note that if {cmd:...} starts and ends
with double quotes, then {cmd:cmd} will strip them (so you might have to add extras).

{marker examples}{...}
{title:Examples}

{pstd}
Example using {cmd:bshell}:

	{cmd:bshell notepad}

