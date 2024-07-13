# Note: USED_IN_SYNTHESIS is disabled to avoid needing to resynthesize whenever changes are made  

# Begin scope to ResetBridge instance
current_instance [get_cells base_sync_inst]
# Reset input to the synchronizer must be ignored for timing analysis
set_false_path -through [get_ports -scoped_to_current_instance aRst]
# Constrain internal synchronizer paths to half-period, which is expected to be easily met with ASYNC_REG=true
set ClkPeriod [get_property PERIOD [get_clocks -of_objects [get_ports -scoped_to_current_instance OutClk]]]
set_max_delay -from [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] -to [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] [expr $ClkPeriod/2]
current_instance -quiet
# End scope to ResetBridge instance

# Begin scope to ResetBridge instance
current_instance [get_cells output_buffers[0]/sync_inst]
# Reset input to the synchronizer must be ignored for timing analysis
set_false_path -through [get_ports -scoped_to_current_instance aRst]
# Constrain internal synchronizer paths to half-period, which is expected to be easily met with ASYNC_REG=true
set ClkPeriod [get_property PERIOD [get_clocks -of_objects [get_ports -scoped_to_current_instance OutClk]]]
set_max_delay -from [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] -to [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] [expr $ClkPeriod/2]
current_instance -quiet
# End scope to ResetBridge instance

# Begin scope to ResetBridge instance
current_instance [get_cells output_buffers[1]/sync_inst]
# Reset input to the synchronizer must be ignored for timing analysis
set_false_path -through [get_ports -scoped_to_current_instance aRst]
# Constrain internal synchronizer paths to half-period, which is expected to be easily met with ASYNC_REG=true
set ClkPeriod [get_property PERIOD [get_clocks -of_objects [get_ports -scoped_to_current_instance OutClk]]]
set_max_delay -from [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] -to [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] [expr $ClkPeriod/2]
current_instance -quiet
# End scope to ResetBridge instance

# Begin scope to ResetBridge instance
current_instance [get_cells output_buffers[2]/sync_inst]
# Reset input to the synchronizer must be ignored for timing analysis
set_false_path -through [get_ports -scoped_to_current_instance aRst]
# Constrain internal synchronizer paths to half-period, which is expected to be easily met with ASYNC_REG=true
set ClkPeriod [get_property PERIOD [get_clocks -of_objects [get_ports -scoped_to_current_instance OutClk]]]
set_max_delay -from [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] -to [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] [expr $ClkPeriod/2]
current_instance -quiet
# End scope to ResetBridge instance

# Begin scope to ResetBridge instance
current_instance [get_cells output_buffers[3]/sync_inst]
# Reset input to the synchronizer must be ignored for timing analysis
set_false_path -through [get_ports -scoped_to_current_instance aRst]
# Constrain internal synchronizer paths to half-period, which is expected to be easily met with ASYNC_REG=true
set ClkPeriod [get_property PERIOD [get_clocks -of_objects [get_ports -scoped_to_current_instance OutClk]]]
set_max_delay -from [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] -to [get_cells OutputFF*.SyncAsyncx/oSyncStages_reg[*]] [expr $ClkPeriod/2]
current_instance -quiet
# End scope to ResetBridge instance
