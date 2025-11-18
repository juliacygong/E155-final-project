if {[catch {

# define run engine funtion
source [file join {C:/lscc/radiant/2025.1} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) "1"
set para(prj_dir) "C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/proj_fft-20251117T072402Z-1-001/proj_fft"
if {![file exists {C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/proj_fft-20251117T072402Z-1-001/proj_fft/fft}]} {
  file mkdir {C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/proj_fft-20251117T072402Z-1-001/proj_fft/fft}
}
cd {C:/Users/User/Desktop/Engr 155/e155-final-project/fpga/radiant_project/proj_fft-20251117T072402Z-1-001/proj_fft/fft}
# synthesize IPs
# synthesize VMs
# synthesize top design
::radiant::runengine::run_postsyn [list -a iCE40UP -p iCE40UP5K -t SG48 -sp High-Performance_1.2V -oc Industrial -top -w -o proj_fft_fft_syn.udb proj_fft_fft.vm] [list proj_fft_fft.ldc]

} out]} {
   ::radiant::runengine::runtime_log $out
   exit 1
}
