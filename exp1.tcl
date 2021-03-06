# Create a Simulator object
set ns [new Simulator]

# TCP variant and  CBR rate
set variant [lindex $argv 0]
set rate [lindex $argv 1]

# Open the trace file
set tf [open ${variant}_${rate}_output.tr w]
$ns trace-all $tf

# Define a 'finish' procedure
proc finish {} {
	global ns tf
	$ns flush-trace
	close $tf
	exit 0
}

# Create 6 nodes
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]


# Create links between the nodes
$ns duplex-link $n1 $n2 10Mb 10ms DropTail
$ns duplex-link $n5 $n2 10Mb 10ms DropTail
$ns duplex-link $n3 $n2 10Mb 10ms DropTail
$ns duplex-link $n3 $n4 10Mb 10ms DropTail
$ns duplex-link $n3 $n6 10Mb 10ms DropTail

# Setting the queue limit
$ns queue-limit $n2 $n3 10

# Setup a TCP connection
if {$variant eq "Tahoe"} {
	set tcp [new Agent/TCP]
} elseif {$variant eq "Reno"} {
	set tcp [new Agent/TCP/Reno]
} elseif {$variant eq "NewReno"} {
	set tcp [new Agent/TCP/Newreno]
} elseif {$variant eq "Vegas"} {
	set tcp [new Agent/TCP/Vegas]
}
$tcp set class_ 2
$ns attach-agent $n1 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n4 $sink
$ns connect $tcp $sink
$tcp set fid_ 1


# Setup FTP over TCP
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

# Add a CBR source at N2
# Setup a UDP connection
set udp [new Agent/UDP]
$ns attach-agent $n2 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 2

# Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ ${rate}mb
$cbr set random_ false


# Schedule events for the CBR and FTP agents
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 8.5 "$ftp stop"
$ns at 9.5 "$cbr stop"

# Call the finish procedure
$ns at 10.0 "finish"

# Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"

# Run the simulation
$ns run

close $tf

