# Create a Simulator object
set ns [new Simulator]


# TCP variant and queue discipline
set variant [lindex $argv 0]
set q_type [lindex $argv 1]


# Open the trace file
set tf [open ${variant}_${q_type}_output.tr w]
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


# Create links between the nodes, modified based on queue disciplines
# "DropTail" and "RED" discipline
if {$q_type eq "RED"} {
    $ns duplex-link $n1 $n2 10Mb 10ms RED
    $ns duplex-link $n5 $n2 10Mb 10ms RED
    $ns duplex-link $n3 $n2 10Mb 10ms RED
    $ns duplex-link $n3 $n4 10Mb 10ms RED
    $ns duplex-link $n3 $n6 10Mb 10ms RED
} elseif {$q_type eq "DropTail"} {
    $ns duplex-link $n1 $n2 10Mb 10ms DropTail
    $ns duplex-link $n5 $n2 10Mb 10ms DropTail
    $ns duplex-link $n3 $n2 10Mb 10ms DropTail
    $ns duplex-link $n3 $n4 10Mb 10ms DropTail
    $ns duplex-link $n3 $n6 10Mb 10ms DropTail
}

# Adding the queue limit to each link
$ns queue-limit $n1 $n2 10
$ns queue-limit $n5 $n2 10
$ns queue-limit $n3 $n2 10
$ns queue-limit $n3 $n4 10
$ns queue-limit $n3 $n6 10


# Setup a TCP connection
if {$variant eq "Reno"} {
	set tcp [new Agent/TCP/Reno]
	set sink [new Agent/TCPSink]
} elseif {$variant eq "SACK"} {
	set tcp [new Agent/TCP/Sack1]
	set sink [new Agent/TCPSink/Sack1]
}
$tcp set class_ 1
$ns attach-agent $n1 $tcp
$ns attach-agent $n4 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

# Setting a window size
$tcp set window_ 80
$tcp set cwnd_ 100

# Setup FTP over TCP
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

# Setting up the UDP connection from node N5 to node N6
set udp [new Agent/UDP]
$ns attach-agent $n5 $udp
set null [new Agent/Null]
$ns attach-agent $n6 $null
$ns connect $udp $null
$udp set fid_ 2

# Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set rate_ 7mb


# Schedule events for the CBR and FTP agents
$ns at 0.1 "$cbr start"
$ns at 3.0 "$ftp start"
$ns at 10.0 "$ftp stop"
$ns at 10.0 "$cbr stop"

# Call the finish procedure
$ns at 10.0 "finish"

# Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"

# Run the simulation
$ns run

close $tf

