if {[catch {

# define run engine funtion
source [file join {C:/lscc/radiant/2025.1} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) "1"
set para(prj_dir) "C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/fft_ramdq"
if {![file exists {C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/fft_ramdq/fftfull}]} {
  file mkdir {C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/fft_ramdq/fftfull}
}
cd {C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/fft_ramdq/fftfull}
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- fft_ramdq_fftfull_cpe.ldc
::radiant::runengine::run_engine_newmsg cpe -syn lse -f "fft_ramdq_fftfull.cprj" "ramdq.cprj" -a "iCE40UP"  -o fft_ramdq_fftfull_cpe.ldc
# synthesize top design
file delete -force -- fft_ramdq_fftfull.vm fft_ramdq_fftfull.ldc
::radiant::runengine::run_engine_newmsg synthesis -f "C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/fft_ramdq/fftfull/fft_ramdq_fftfull_lattice.synproj" -logfile "fft_ramdq_fftfull_lattice.srp"
::radiant::runengine::run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o fft_ramdq_fftfull_syn.udb fft_ramdq_fftfull.vm] [list fft_ramdq_fftfull.ldc]

} out]} {
   ::radiant::runengine::runtime_log $out
   exit 1
}
