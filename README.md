# AWS ELB EC2 Web Host Cluster
***
Creates a cluster of EBS backed EC2 instances as web hosts in an ASG, load 
balanced via ELB across all AZ's in a region. Register existing domain 
name and route web traffic to ELB utilizing R53.