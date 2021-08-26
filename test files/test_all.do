//Setup
include setup_ado.do
//Don't need to log PATH or set STATATMP

//Keep synced with makefile:TESTS
loc test_bases "test_bs test_append test_sim test_prefix test test_append_loop test_length test_aux_out test_seeding"


//Since we're running this interactively, we don't have to make separate logs and then concatenate
foreach test_base of local test_bases {
	do `test_base'.do
	display "test `test_base'.do done"
}
