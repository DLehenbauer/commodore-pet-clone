set module [lindex $quartus(args) 0]
set project [lindex $quartus(args) 1]
set revision [lindex $quartus(args) 2]

if [string match $module "quartus_asm"] {
    post_message "Programming device"
    qexec "quartus_pgm output_files/PET.cdf"
    post_message "Restarting target"
    qexec "ssh pi@rpi3.local \"sudo killall -9 main; sudo ./main || true\""
}
