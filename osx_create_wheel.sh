#!/bin/bash

# The script pulls the bohrium repos and use create_wheel.py to create a PIP package
# Use this script on a MAC OSX platform with homebrew and python installed.
#
# Command line arguments:
#   1) Set the first argument to the name of the branch to pull from
#   2) Set the second argument to "testing" if you want to test the wheel package
#   3) Set the third argument to "deploy" if you want to upload the wheel package to PIP,
#      in which case you need to set the envs TWINE_USERNAME and TWINE_PASSWORD

if [ "$#" -ne "3" ];
    then echo "illegal number of parameters -- e.g. master testing nodeploy"
fi

set -e
set -x
unset PYTHONPATH
export BH_OPENMP_PROF=true
export BH_OPENMP_VOLATILE=true
export BH_OPENCL_PROF=true
export BH_OPENCL_VOLATILE=true

# Let's install the different versions of Python
brew install python@2 || true
# Python v3.6.5 recipe
brew install -f https://raw.githubusercontent.com/Homebrew/homebrew-core/f2a764ef944b1080be64bd88dca9a1d80130c558/Formula/python.rb
# Python v3.7.1 recipe
brew unlink python
brew install -f https://raw.githubusercontent.com/Homebrew/homebrew-core/2b73054ccd723a3ce4c556fd879f08fd8e70d698/Formula/python.rb
brew unlink python

# We find the first glob match for each Python binary
PY27=$(ls /usr/local/Cellar/python@2/2.7.*/bin/python2 | head -n1)
PY36=$(ls /usr/local/Cellar/python/3.6.*/bin/python3 | head -n1)
PY37=$(ls /usr/local/Cellar/python/3.7.*/bin/python3 | head -n1)
$PY27 --version
$PY36 --version
$PY37 --version
# For some reason virtualenv will use this specific path when using python3.6
ln -s $PY36 /usr/local/opt/python/bin/python3.6

# Install dependencies
brew install cmake || true
brew install boost --with-icu4c || true
brew install libsigsegv || true
brew install clblas || true
#brew install opencv || true
$PY27 -m pip install virtualenv

# Download source into `~/bh`
git clone https://github.com/bh107/bohrium.git --branch $1
mv bohrium ~/bh
mv delocate ~/bh/
mkdir ~/bh/build
cd ~/bh/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DEXT_VISUALIZER=OFF -DVEM_PROXY=OFF \
         -DPYTHON_EXECUTABLE=$PY27 \
         -DCMAKE_INSTALL_PREFIX=~/bh/install \
         -DPY_WHEEL=~/wheel \
         -DPY_EXE_LIST="$PY27;$PY36;$PY37" \
         -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
make -j 2
make install
cmake --version
otool -L filter/bccon/libbh_filter_bccon.dylib
otool -L core/libbh.dylib

$PY27 -m virtualenv ~/vr27
source ~/vr27/bin/activate
pip install ~/bh/delocate/
pip install numpy cython scipy gcc7
delocate-listdeps `ls ~/wheel/bohrium_api-*.whl`
delocate-wheel `ls ~/wheel/bohrium_api-*.whl`
delocate-listdeps `ls ~/wheel/bohrium_api-*.whl`

pip install `ls ~/wheel/bohrium_api-*-cp27*.whl`
python -c "import bohrium_api; print(bohrium_api.__version__)"
pip install `ls ~/wheel/bohrium-*-cp27*.whl`
BH_STACK=opencl python -m bohrium --info
deactivate

$PY27 -m virtualenv -p $PY36 ~/vr36
source ~/vr36/bin/activate
pip install numpy cython scipy gcc7
pip install `ls ~/wheel/bohrium_api-*-cp36*.whl`
python -c "import bohrium_api; print(bohrium_api.__version__)"
pip install `ls ~/wheel/bohrium-*-cp36*.whl`
BH_STACK=opencl python -m bohrium --info
deactivate

$PY27 -m virtualenv -p $PY37 ~/vr37
source ~/vr37/bin/activate
pip install numpy cython scipy gcc7
pip install `ls ~/wheel/bohrium_api-*-cp37*.whl`
python -c "import bohrium_api; print(bohrium_api.__version__)"
pip install `ls ~/wheel/bohrium-*-cp37*.whl`
BH_STACK=opencl python -m bohrium --info
deactivate

# Testing of the wheel package
if [ "$2" = "testing" ]; then
    TESTS=~/bh/test/python/tests/test_array_create.py

    source ~/vr27/bin/activate
    python ~/bh/test/python/run.py $TESTS
    deactivate

    source ~/vr36/bin/activate
    python ~/bh/test/python/run.py $TESTS
    deactivate

    source ~/vr37/bin/activate
    python ~/bh/test/python/run.py $TESTS
    deactivate
else
    echo 'Notice, if you want to run test set second argument to "testing"'
fi

# Deploy, remember to define TWINE_USERNAME and TWINE_PASSWORD
if [ "$3" = "deploy" ]; then
    source ~/vr27/bin/activate
    pip install twine
    twine upload `ls ~/wheel/bohrium_api-*.whl` || true
    deactivate
else
    echo 'Notice, if you want to run test set third argument to "deploy"'
fi


