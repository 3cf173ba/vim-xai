#!/bin/bash

REQUIRED_BINARIES="perl cpan cpanm"
REQUIRED_PERL_MODULES="JSON LWP::UserAgent LWP::Protocol::https"
CPAN_FLAGS="-Ti" # Do not test module, install
CPANM_FLAGS="-n" # Do not test module
# Answer defaults for cpan conifguration.
export PERL_MM_USE_DEFAULT=1
# Check for necessary binaries and set evaluated variable to 1
# if binary is present.
# Variable names are items of REQUIRED_BINARIES to upper case.
for binary in $REQUIRED_BINARIES; do
    b=$(echo $binary | tr 'a-z' 'A-Z')
    eval "$b=$(which $binary >/dev/null 2>&1 && echo 1)"
done

# Check for required perl modules.
check_pm() {
    OK="ok"
    for pm in $REQUIRED_PERL_MODULES; do
        perl -e "use $pm;">/dev/null 2>&1
        if [ $? != 0 ]; then
            OK=""
            break
        fi
    done

    if [ -z $OK ]; then
        return 0
    else
        return 1
    fi
}

# Function to install cpanminus perl module
install_cpanminus() {
    ARCH=`uname`
    if [ "$ARCH" == "Darwin" ]; then
        echo "Please use brew to install cpanminus and run this script again."
        exit 0
    fi
    echo -n 'cpanminus is not installed, I can do that for you. Continue? [Y|n]'
    read y
    [ "`echo $y | tr 'a-z' 'A-Z'`" == "N" ] && echo "aborting ..." && exit 0
    cpan $CPAN_FLAGS App::cpanminus
}

install_perl_deps() {
    echo "Installing perl modules ..."
    for m in $REQUIRED_PERL_MODULES; do
        perl -e "use $m;">/dev/null 2>&1
        if [ $? != 0 ]; then
           cpanm $CPANM_FLAGS $m \
               || echo "Error(s) occured, aborting ..." \
               || exit 1
        fi
    done
}

[ -z $PERL ] && echo "Perl is required, please install it first." && exit 1
[ -z $CPAN ] && echo "cpan is not installed, please install it first" && exit 1
[ -z $CPANM ] && install_cpanminus
echo "All binaries present."
check_pm && install_perl_deps || echo "All required perl modules are installed."
