#!/bin/bash

# The script pulls the bohrium repos and use create_wheel.py to create a PIP package
# Use this script on a MAC OSX platform with homebrew and python installed.
#
# Command line arguments:
#   1) Set the first argument to the name of the branch to pull from
#   2) Set the third argument to "testing" if you want to test the wheel package
#   3) Set the fourth argument to "deploy" if you want to upload the wheel package to PIP,
#      in which case you need to set the envs TWINE_USERNAME and TWINE_PASSWORD

if [ "$#" -ne "3" ];
    then echo "illegal number of parameters -- e.g. master 2.7 testing nodeploy"
fi

set -e
set -x
unset PYTHONPATH
export BH_OPENMP_PROF=true
export BH_OPENMP_VOLATILE=true
export BH_OPENCL_PROF=true
export BH_OPENCL_VOLATILE=true

brew install python@2
brew install python@3
brew install cmake || true
brew install boost --with-icu4c || true
brew install libsigsegv || true
brew install clblas || true
#brew install opencv || true
python2 -m pip install virtualenv --user
python3 -m pip install virtualenv --user

# Download source into `~/bh`
git clone https://github.com/bh107/bohrium.git --branch $1
mv bohrium ~/bh
mv delocate ~/bh/
mkdir ~/bh/build
cd ~/bh/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DEXT_VISUALIZER=OFF -DVEM_PROXY=OFF \
         -DPYTHON_EXECUTABLE=/usr/local/bin/python2 \
         -DCMAKE_INSTALL_PREFIX=~/bh/install \
         -DPY_WHEEL=~/wheel \
         -DPY_EXE_LIST="/usr/local/bin/python2;/usr/local/bin/python3"
make -j 2
make install

/usr/local/bin/python2 -m virtualenv ~/vr2
source ~/vr2/bin/activate
pip install ~/bh/delocate/
pip install numpy cython scipy gcc7
delocate-wheel `ls ~/wheel/bohrium_api-*.whl`
delocate-listdeps `ls ~/wheel/bohrium_api-*.whl`

pip install `ls ~/wheel/bohrium_api-*-cp2*.whl`
python -c "import bohrium_api; print(bohrium_api.__version__)"
pip install `ls ~/wheel/bohrium-*-cp2*.whl`
BH_STACK=opencl python -m bohrium --info
deactivate

/usr/local/bin/python3 -m virtualenv ~/vr3
source ~/vr3/bin/activate
pip install numpy cython scipy gcc7
pip install `ls ~/wheel/bohrium_api-*-cp3*.whl`
python -c "import bohrium_api; print(bohrium_api.__version__)"
pip install `ls ~/wheel/bohrium-*-cp3*.whl`
BH_STACK=opencl python -m bohrium --info
deactivate

# Testing of the wheel package
if [ "$2" = "testing" ]; then
#    # We have to skip some tests because of time constraints on travis-ci.org
#    set +x
#    TESTS=""
#    for t in `ls ~/bh/test/python/tests/test_*.py`; do
#        if ! [[ $t =~ (mask|reorganization|summations) ]]; then
#            TESTS="$TESTS $t"
#        fi
#    done
#    set -x
 #   TESTS=`ls ~/bh/test/python/tests/test_primitives.py` `ls ~/bh/test/python/tests/test_ext_*`
    TESTS=~/bh/test/python/tests/test_primitives.py

    source ~/vr2/bin/activate
    python ~/bh/test/python/run.py $TESTS
    deactivate

    source ~/vr3/bin/activate
    python ~/bh/test/python/run.py $TESTS
    deactivate
else
    echo 'Notice, if you want to run test set second argument to "testing"'
fi

# Deploy, remember to define TWINE_USERNAME and TWINE_PASSWORD
if [ "$3" = "deploy" ]; then
    source ~/vr2/bin/activate
    pip install twine
    twine upload `ls ~/wheel/bohrium_api-*.whl`
    deactivate
else
    echo 'Notice, if you want to run test set third argument to "deploy"'
fi


