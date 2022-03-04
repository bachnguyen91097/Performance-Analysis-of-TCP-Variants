# Create a Simulator object
set ns [new Simulator]

# TCP variants and  CBR rate
set v1 [lindex $argv 0]
set v2 [lindex $argv 1]
set rate [lindex $argv 2]

# Open the trace file
set tf [open ${v1}_${v2}_${rate}_output.tr w]
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

# Setting up the queue limit
$ns queue-limit $n2 $n3 10

# Set up first TCP connection
if {$v1 eq "Reno"} {
	set tcp1 [new Agent/TCP/Reno]
} elseif {$v1 eq "NewReno"} {
	set tcp1 [new Agent/TCP/Newreno]
} elseif {$v1 eq "Vegas"} {
	set tcp1 [new Agent/TCP/Vegas]
}
$tcp1 set class_ 2
$ns attach-agent $n1 $tcp1
set sink1 [new Agent/TCPSink]
$ns attach-agent $n4 $sink1
$ns connect $tcp1 $sink1
$tcp1 set fid_ 1


# Set up second TCP connection
if {$v2 eq "Reno"} {
	set tcp2 [new Agent/TCP/Reno]
} elseif {$v2 eq "Vegas"} {
	set tcp2 [new Agent/TCP/Vegas]
}
$tcp2 set class_ 3
$ns attach-agent $n5 $tcp2
set sink2 [new Agent/TCPSink]
$ns attach-agent $n6 $sink2
$ns connect $tcp2 $sink2
$tcp1 set fid_ 3

# Setup first FTP over TCP connection
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

# Setup second FTP over TCP connection
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

# Setup a UDP connection
set udp [new Agent/UDP]
$ns attach-agent $n2 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null

# Setup a CBR over UDP connection
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
# Change rate until TCP can reach its bottleneck
$cbr set rate_ ${rate}mb
$cbr set random_ false

# Schedule events for the CBR and FTP agents
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp1 start"
$ns at 1.0 "$ftp2 start"
$ns at 8.5 "$ftp1 stop"
$ns at 8.5 "$ftp2 stop"
$ns at 9.5 "$cbr stop"

# Call the finish procedure
$ns at 10.0 "finish"

#Print CBR packet size and interval
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"

#Run the simulation
$ns run


close $tf