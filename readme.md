### Setting up the docker image

Run "./build\_image.sh" to build the image.
Run "./run\_interactive\_image.sh" to start an interactive session.

### Compiling

First make sure you're in an interactive session inside the image.
Source the fuzzing environment (". fuzz\_env.sh").
Run the build script, "./build\_afl.sh"

### Fuzzing

From inside an interactive session, run start script. Make sure to specify the output directory. Note that the directory "output" is mounted to the local output directory so that output files can be stored locally.
Example execution: ./start.sh output/fuzzout.0
