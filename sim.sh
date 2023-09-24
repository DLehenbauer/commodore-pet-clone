#!/bin/bash

PROJDIR="$(cd "$(dirname "$0")/gw/PET" && pwd)"
echo "PROJDIR: $PROJDIR"

# Parse command-line arguments
TOPMODULE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --view)
            View=true
            shift
            ;;
        *)
            if [ -z "$TOPMODULE" ]; then
                TOPMODULE="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$TOPMODULE" ]; then
    TOPMODULE="sim"
fi

# Run step
if [ -z "$View" ]; then
    pushd "$PROJDIR" > /dev/null
    iverilog -g2009 -s "$TOPMODULE" -o "$PROJDIR/work_sim/PET.vvp" -f "$PROJDIR/work_sim/PET.f"
    if [ $? -ne 0 ]; then
        popd > /dev/null
        exit $?
    fi

    vvp -l "$PROJDIR/outflow/PET.rtl.simlog" "$PROJDIR/work_sim/PET.vvp"
    exitcode=$?
    popd > /dev/null
    exit $exitcode
fi

# View step
if [ "$View" = "true" ]; then
    open -a gtkwave "$PROJDIR/work_sim/out.vcd" &
    exit $?
fi
