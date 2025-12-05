if {[catch {

# define run engine funtion
source [file join {C:/lscc/radiant/2025.1} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) "1"
set para(prj_dir) "C:/Users/User/Desktop/proj_fft"
if {![file exists {C:/Users/User/Desktop/proj_fft/fft}]} {
  file mkdir {C:/Users/User/Desktop/proj_fft/fft}
}
cd {C:/Users/User/Desktop/proj_fft/fft}
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- proj_fft_fft_cpe.ldc
::radiant::runengine::run_engine_newmsg cpe -syn lse -f "proj_fft_fft.cprj" "ramdualpt.cprj" "ramdp8b.cprj" -a "iCE40UP"  -o proj_fft_fft_cpe.ldc
# synthesize top design
file delete -force -- proj_fft_fft.vm proj_fft_fft.ldc
::radiant::runengine::run_engine_newmsg synthesis -f "C:/Users/User/Desktop/proj_fft/fft/proj_fft_fft_lattice.synproj" -logfile "proj_fft_fft_lattice.srp"
::radiant::runengine::run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o proj_fft_fft_syn.udb proj_fft_fft.vm] [list proj_fft_fft.ldc]

} out]} {
   ::radiant::runengine::runtime_log $out
   exit 1
}
