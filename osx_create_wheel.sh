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

PY27=/opt/py2.7/bin/python2.7
PY36=/opt/py3.6/bin/python3.6
PY37=/opt/py3.7/bin/python3.7
$PY27 --version
$PY36 --version
$PY37 --version
sudo $PY36 -m pip install virtualenv

# Install dependencies
brew install cmake || true
brew install boost --with-icu4c || true
brew install libsigsegv || true
brew install clblas || true
#brew install opencv || true

# Download source into `~/bh`
git clone https://github.com/bh107/bohrium.git --branch $1
mv bohrium ~/bh
mv delocate ~/bh/
mkdir ~/bh/build
cd ~/bh/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DEXT_VISUALIZER=OFF -DVEM_PROXY=OFF \
         -DPYTHON_EXECUTABLE=$PY36 \
         -DCMAKE_INSTALL_PREFIX=~/bh/install \
         -DPY_WHEEL=~/wheel \
         -DPY_EXE_LIST="$PY27;$PY36;$PY37" \
         -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON
make -j 2
make install
cmake --version
otool -L filter/bccon/libbh_filter_bccon.dylib
otool -L core/libbh.dylib

$PY36 -m virtualenv -p $PY27 ~/vr27
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
pip install ~/bh/bridge/bh107/
cd ~/bh/bridge/bh107/ && python setup.py sdist -d ~/sdisthouse/
deactivate

$PY36 -m virtualenv -p $PY36 ~/vr36
source ~/vr36/bin/activate
pip install numpy cython scipy gcc7
pip install `ls ~/wheel/bohrium_api-*-cp36*.whl`
python -c "import bohrium_api; print(bohrium_api.__version__)"
pip install `ls ~/wheel/bohrium-*-cp36*.whl`
BH_STACK=opencl python -m bohrium --info
pip install ~/bh/bridge/bh107/
cd ~/bh/bridge/bh107/ && python setup.py sdist -d ~/sdisthouse/
deactivate

$PY36 -m virtualenv -p $PY37 ~/vr37
source ~/vr37/bin/activate
pip install numpy cython scipy gcc7
pip install `ls ~/wheel/bohrium_api-*-cp37*.whl`
python -c "import bohrium_api; print(bohrium_api.__version__)"
pip install `ls ~/wheel/bohrium-*-cp37*.whl`
BH_STACK=opencl python -m bohrium --info
pip install ~/bh/bridge/bh107/
cd ~/bh/bridge/bh107/ && python setup.py sdist -d ~/sdisthouse/
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
    twine upload `ls ~/sdisthouse/*` || true
    deactivate
else
    echo 'Notice, if you want to upload the packages set third argument to "deploy"'
fi


