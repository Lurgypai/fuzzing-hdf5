import shutil
import subprocess
import threading
import argparse
import os
import time
import math
import sys

AFLPP = ""
AFLFUZZ = os.path.join(AFLPP, "afl-fuzz")
AFLWHATSUP = os.path.join(AFLPP, "afl-whatsup")

def work(cpu, args):
    master_slave = '-S'
    if cpu == 0:
        master_slave = '-M'

    try:
        print("Starting core {}".format(cpu))
        cmd = [
            # Set this thread to the given CPU core
            "taskset", "-c", "{}".format(cpu),
            AFLFUZZ,
            "-i", args.input_dir,
            "-o", args.output_dir,
            master_slave, "fuzz_{}".format(cpu),
        ]

        # If we have a timeout, use it
        if args.timeout:
            cmd.extend(["-t", args.timeout])

        # If given a cmplog binary, add the cmplog binary and no memory 
        # restriction to the command line
        if args.cmplog:
            cmd.extend(["-c", args.cmplog, "-m", "none"])

        # If we have a power identifier, use it as well
        if args.power:
            cmd.extend(["-p", args.power])

        # Finish off with the actual binary
        cmd.extend(["--", args.binary])

        # .. and any binary arguments
        arguments = [x for arg in args.arguments for x in arg.split()]
        cmd.extend(arguments)

        print(' '.join(cmd))

        # Execute the command
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        (out, err) = proc.communicate()
        print(out.decode("utf-8"))
        print(err.decode("utf-8"))

    except Exception as e:
        print(str(e))

    print("Core {} died.. ".format(cpu))

NUM_CORES = 16

# Prepare the command line argument parsing
parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input_dir", help="Directory with initial corpus")
parser.add_argument("-o", "--output_dir", help="Directory with output corpus")
parser.add_argument("-t", "--timeout", help="Test timeout (in ms)")
parser.add_argument("-c", "--cores", help="Number of cores to utilize.",
        default=NUM_CORES, type=int)
parser.add_argument("-b", "--binary", help="Binary to execute to fuzz")
parser.add_argument("--asan", help="Binary to execute to fuzz with asan")
parser.add_argument("--ubsan", help="Binary to execute to fuzz with ubsan")
parser.add_argument("--nocmplog", help="Binary to execute to fuzz without cmplog")
parser.add_argument("--cmplog", help="CmpLog enabled binary")
parser.add_argument("arguments", nargs="*", help="Arguments passed to the binary")


# Parse the arguments 
args = parser.parse_args()

print(args)


# Sanity check to make sure we are in bulk execution or single execution mode
if args.binary and (args.asan or args.ubsan or args.nocmplog):
    print("Binary only set on single execution mode.. Found binary along with asan, \
            ubsan, or nocmplog")
    sys.exit(1)


# Init number of cores per build type
ubsan_cores  = 0
asan_cores   = 0
cmplog_cores = 0

# If we are in bulk execution mode (not single mode via --binary), calculate the number
# of cores for each type of binary
if not args.binary:
    # Current number of cores available to allocate
    num_cores = args.cores 

    # Give 10% of the total cores to Undefined Behavior Sanitizer
    if args.ubsan:
        ubsan_cores  = math.floor(num_cores * 0.10)
        if ubsan_cores == 0:
            ubsan_cores  = 1
        print(ubsan_cores)
        num_cores -= ubsan_cores
        print(num_cores)
        print(f"UBSAN cores:  {ubsan_cores}")

    # Give 30% of the total cores to Address Sanitizer
    if args.asan:
        asan_cores  = math.floor(num_cores * 0.30)
        if asan_cores == 0:
            asan_cores  = 1
        num_cores -= asan_cores
        print(f"ASAN cores:   {asan_cores}")

    # Cmplog gets the remaining cores
    cmplog_cores = num_cores

    print(f"CMPLOG cores: {cmplog_cores}")

# Create the output directory if it doesn't exist
if not os.path.exists(args.output_dir):
    print("Creating the output directory")
    os.mkdir(args.output_dir)

# We are scheduling the targets in this script, no need for AFL to do it
print("Setting no AFL affinity")
os.environ["AFL_NO_AFFINITY"] = "1"

# The various power schedules with `-p` determines the selection method for inputs from
# the queue
power_schedules = [
    "fast", "explore", "coe", "quad", "lin", "exploit", "mmopt", "rare", "seek"
]

# Starting pinning cores after all other instances of afl-fuzz
# Defaults to 0 if no other afl-fuzz commands are running
try:
    starting_core = len(subprocess.check_output(["pgrep", AFLFUZZ]).split())
    print("Starting core: ", starting_core)
except Exception as e:
    starting_core = 0

if not args.binary:
    print(f"Executing CMPLOG on {cmplog_cores} cores")
    for cpu in range(starting_core, starting_core + cmplog_cores):
        # Set the binary for this execution to be the nocmplog binary
        args.binary = args.nocmplog

        # Select one of the given power schedules linearly
        args.power = power_schedules[cpu % len(power_schedules)]

        threading.Timer(0, work, args=[cpu, args]).start()

        if cpu == 0:
            time.sleep(1.0)
    starting_core += cmplog_cores

    print(f"Executing ASAN on {asan_cores} cores")
    for cpu in range(starting_core, starting_core + asan_cores):
        # Set the binary for this execution to be the ASAN build
        args.binary = args.asan
        threading.Timer(0, work, args=[cpu, args]).start()
    starting_core += asan_cores

    print(f"Executing UBSAN on {ubsan_cores} cores")
    for cpu in range(starting_core, starting_core + ubsan_cores):
        # Set the binary for this execution to be the UBSAN build
        args.binary = args.asan
        threading.Timer(0, work, args=[cpu, args]).start()
    starting_core += ubsan_cores
else:
    # Single binary execution
    for cpu in range(starting_core, starting_core + args.cores):
        # Select one of the given power schedules linearly
        args.power = power_schedules[cpu % len(power_schedules)]

        threading.Timer(0, work, args=[cpu, args]).start()
        if cpu == 0:
            time.sleep(1.0)


while threading.active_count() > 1:
    time.sleep(10)

    try:
        # Execute afl-whastup in summary mode
        subprocess.check_call([AFLWHATSUP, "-s", args.output_dir])
    except:
        pass
