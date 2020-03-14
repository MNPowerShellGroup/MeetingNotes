# https://docs.universaldashboard.io/rest-apis
# docker build likes all the stuff in one place
# build it
docker build . -t udbtest
# run it -- make sure the port numbers here match whats in your script
docker run -d --rm -p 8085:8085 --name te udbtest

# test your code before you bother to build it (save a lot of time)
# edit your script, run container, test, destroy container.  Once you start the container it loads the script into memory so if you make changes you have to kill the container and relaunch it
# looks a litte goofy but you have to override the entry point
docker run -d --rm -p 8085:8085 --name te -v ${pwd}:/home --entrypoint pwsh udbtest /home/example.ps1
# test it
# static get
Invoke-WebRequest http://localhost:8085/api/thing -UseBasicParsing | ConvertFrom-Json
# last part of uri is variable
Invoke-WebRequest http://localhost:8085/api/thing2/pwssdf -UseBasicParsing | ConvertFrom-Json
# send in hash table for staticly defined arguments
Invoke-WebRequest http://localhost:8085/api/thing3 -Method Post -Body @{arg1="yarb";arg2="supbro"} -UseBasicParsing | ConvertFrom-Json
# send standard json
Invoke-WebRequest http://localhost:8085/api/thing4 -Method Post -Body (@{yip="yarb";whatup="supbro"} | ConvertTo-Json) -UseBasicParsing | ConvertFrom-Json
# kill it
docker kill te

# run the built product
docker run -d --rm -p 8085:8085 --name te nexxus916/udsample:0.1
