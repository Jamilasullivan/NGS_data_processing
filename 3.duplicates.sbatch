#!/bin/bash

#SBATCH --job-name=[for all related scripts]            # Give your job a name
#SBATCH --output=logs/sample_%j.out                     # Where to save stdout
#SBATCH --error=                                        # Where to save stderr
#SBATCH --time=                                         # Max wall-clock runtime
#SBATCH --cpus-per-task=8                               # Number of CPU cores to allocate
#SBATCH --mem=16G                                       # Total memory (RAM) requested
#SBATCH --partition=                                    # Which queue/partition to run on
#SBATCH --nodes=                                        # Number of compute nodes
#SBATCH --ntasks=                                       # Number of tasks (MPI jobs)
#SBATCH --mail-type=                                    # When to send email notifications
#SBATCH --mail-user=                                    # Your email address
#SBATCH --dependency=                                   # Run only after another job finishes
#SBATCH --account or --qos                              # Billing/project code
#SBATCH --job-name + -d singleton                       # Only one job with this name at a time
