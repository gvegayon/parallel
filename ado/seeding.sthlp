{smcl}
{* *! version 1.20.1 07jun2021}{...}
{vieweralsosee "parallel" "help parallel"}{...}
{cmd:help seeding}
{hline}

{title:Title}

{phang}
{bf:seeding} {hline 2} Stata module to run loop iterations involving randomness 
with identical results when run sequentially or in parallel.


{marker syntax}{...}
{title:Syntax}

{col 5}{hline}{marker initialize}{...}
{pstd}Aggregate results in return statements via {cmdab:simulate}.

{p 8 17 2}
{cmd:seeding simulate}
	{it:{help exp_list}}
	[{cmd:,} {opt r:eps(#)} {opt parallel} {opt parallel_opts(options)} {it:simulate_options}]
	{cmd::} {it:command}

{col 5}{hline}{marker numprocessors}{...}
{pstd}Aggregate results via {cmdab:post}

{p 8 17 2}
{cmd:seeding sim_to_post} 
	{it:{help newvarlist}}
	[{cmd:,} {opt r:eps(#)} {opt parallel} {opt parallel_opts(options)} {it:sim_to_post_options}]
	{cmd::} {it:command}

{synoptset 23 tabbed}{...}
{marker options_table}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opt r:eps(#)}}perform {it:#} random permutations; default is {cmd:reps(100)}{p_end}
{synopt :{opt parallel}}compute the iterations using {cmd:parallel}. Must have specified the
cluster using {cmd:parallel setclusters}. Default is non-parallel (sequential).{p_end}
{synopt :{opt parallel_opts(string)}}options passed to {help prefix_saving_option:{cmd:parallel}}. If you have a local 
program (not in an .ado) then you will want to specify it using {opt programs(program_name)}.{p_end}

{syntab :Options}
{synopt :{opt simulate_options}}Currently supported (see {help simulate} for more details): {opt nodots} {opt noisily} 
{opt nolegend} {opt verbose}.{p_end}
{synopt :{opt sim_to_post_options}}Subset of those used for simulate. Currently supported: {opt nodots}.{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:seeding} executes {it:command} for each repetition. It specifies the RNG seed to a new value before each iteration 
allowing results to be identical between sequential and parallel execution. It also defines globals {cmd:REP_gl_i} 
(the global iteration number) and {cmd:REP_lc_i} (the local iteration number, which differs from {cmd:REP_gl_i} if 
this is in a {cmd:parallel} sub-process) that may be used by {it:command}. The main data is replaced with the results.

{pstd}
{cmd:seeding simulate/sim_to_post} do not preserve the dataset between iterations, though if results depend on sequential 
modifications to the main data this may not be reproducible as in parallel mode, each child cluster starts with the initial data.

{pstd}
{cmd:seeding sim_to_post} requires that {it:command} accepts the option {it:postname(string)} as the place to store data.

{marker examples}{...}
{title:Examples}

{pstd}
Example using {cmd:simulate}:

	{cmd:program define lnsim, rclass}
		{cmd:syntax [, obs(integer 1) mu(real 0) sigma(real 1) ]}
		{cmd:drop _all}
		{cmd:set obs `obs'}
		{cmd:tempvar z}
		{cmd:gen `z' = exp(rnormal(`mu',`sigma'))}
		{cmd:summarize `z'}
		{cmd:return scalar mean = r(mean)}
		{cmd:return scalar Var  = r(Var)}
	{cmd:end}
	{cmd:parallel setclusters 2}
	{cmd:set seed 1337}
	{cmd:seeding simulate mean=r(mean) var=r(Var), reps(100) parallel parallel_opts(programs(lnsim)): lnsim, obs(100)}
	{cmd:set seed 1337}
	{cmd:seeding simulate mean=r(mean) var=r(Var), reps(100): lnsim, obs(100)}

{pstd}
Both produce identical results.


{pstd}
Example using {cmd:sim_to_post}:

	{cmd:program my_sp_post}
		{cmd:syntax, postname(string)}
		{cmd:post `postname' (`=runiform()') ($REP_gl_i)}
	{cmd:end}
	{cmd:parallel setclusters 2}
	{cmd:set seed 1337}
	{cmd:seeding sim_to_post float(rand) int(i), reps(100) parallel parallel_opts(programs(my_sp_post)): my_sp_post}
	{cmd:set seed 1337}
	{cmd:seeding sim_to_post float(rand) int(i), reps(100): my_sp_post}

{pstd}
Both produce identical results.
{p_end}
