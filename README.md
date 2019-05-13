# AWS ELB EC2 Web Host Cluster

## Using

Terraform v0.11.13 + provider.aws v1.56.0 

Powershell v5.1.17763.316

<br />

## Description

Creates a cluster of EBS backed EC2 instances as web hosts in an ASG, load 
balanced via ELB across all AZ's in a region. Register existing domain 
name and route web traffic to ELB utilizing R53.

<br />

#### Requirement
:warning: Assumes existence of Route53 hosted zone for dns name.