# prevent printing every cmd before exec it
set echo 0


#--------------------------------------------------------------
# calc_print_diff
# calculate sim time and wallclock time diffs from last call
# and print dbg msg
# -------------------------------------------------------------
proc calc_print_diff {} {
  
  # link global vars to local 
  upvar 1 prev_wc loc_prev_wc
  upvar 1 prev_sim loc_prev_sim
  
  # latch current timestamps
  set curr_wc [clock seconds]
  set curr_sim [time ns]

  # calc diff
  set diff_wc [expr {$curr_wc-$loc_prev_wc}]
  set diff_sim [time -operation -subtime $curr_sim $loc_prev_sim]
 
  puts "SIM_PROG_DBG: sim time diff: $diff_sim - wc time diff: $diff_wc"
  
  # store latched values
  set loc_prev_wc $curr_wc
  set loc_prev_sim $curr_sim
}


#--------------------------------------------------------------
# run_wrapper
# wrap run command with catch, so it could be affected by 
# verilog $finish
#--------------------------------------------------------------
proc run_wrapper {x} {
  catch { run $x } a
  return [string match *RNFNSH* $a]
}


#--------------------------------------------------------------
# script body
#--------------------------------------------------------------

# print first dbg msg 
puts "SIM_PROG_DBG: starting monitoring simulation at: [clock format [clock seconds] -format %H:%M:%S]"


# latch current timestamps
set prev_wc [clock seconds]
set prev_sim [time ns]

sn  config run -exit_on=command

# run 1ns, practically 0+
run_wrapper 1ns


# call proc for the first time, to get seconds cound for 1ns
calc_print_diff


# check if to exit after 1ns - usefull to measure how much time
# simulator hangs on time 0ns
if {[info exists ::env(SIM_PROG_DBG_EXIT_AFTER_1NS)]} {
  finish
  exit
}


# check how many us to run and print timestamps
# default is 60 (enough to finish reset phase)
if {[info exists ::env(SIM_PROG_DBG_RUN_US)]} {
  set loop_cnt [expr {$::env(SIM_PROG_DBG_RUN_US)}]
} else {
  set loop_cnt 60
}

puts "SIM_PROG_DBG: will continue sim for ${loop_cnt} us"

# run simulation and print timestamps every 1us
for {set ii 0} {$ii<$loop_cnt} {set ii [expr {$ii+1}]} {
  if { [run_wrapper 1000ns] } break 
  
  calc_print_diff
}

#run
finish
exit
