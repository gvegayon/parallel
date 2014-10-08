# Must have Cygwin installed. 
# Must have the environment variable STATAEXE defined (and found in path)
# The working directory should be in the tests folder.

# Windows setup
function cleanup {
  rm -f pll_gateway.sh
}
trap cleanup EXIT

rm -f pll_gateway.sh
touch pll_gateway.sh
tail -f pll_gateway.sh | bash &

# Do the parallel jobs
$STATAEXE /e do test.do

# Cleanup
kill $!
rm -f pll_gateway.sh
