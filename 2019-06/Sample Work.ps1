##
# CMD Ref https://docs.docker.com/engine/reference/run/
##

## Primer variables, only need when connecting to a remote Container Host.  all docker commands use $dkrRemote but if you are running locally just leave this variable blank and it works fine
    $cHost = ''
    $dkrRemote = "-H tcp://$($cHost):2375"
    $dkrRemote = "-H tcp://$($cHost):2376"
    $dkrRemote = $null # clear to run against local
    # after a lot of hammering, the following worked.  You can't put --tlsvery in the string .. no idea why.  also certs all have to be in the default .docker folder as specificed in docker --help
    docker --tlsverify  $dkrRemote  images 

#region quick links
    # These 2 are Windows specific
    Enter-PSSession $cHost # connect to container host
    Enter-PSSession -ContainerId $cid -RunAsAdministrator # connect to container  Your Powershell session has to be running as admin (boo)

    ## Removing/Stoping containers
    docker $dkrRemote rm $cid -f # Stop and remove a specific container by ID immediately (when you fire up a container it will return the ID, you can save that into a variable)
    docker stop $cid # Tell the container to shutdown but give it time, 10 seconds max
    docker kill $cid # Kill container immediately 
    docker $dkrRemote ps -aq | ForEach-Object {docker $dkrRemote rm $_ -f} ## Kill all running containsers (docker ps -aq will retun just a lit of IDs and $_ is the current ID as part of foreach-object)
    docker $dkrRemote rm $name -f # when you spin up a container you can give it a name and kill it by name
    docker $dkrRemote ps -q -f ancestor=swaggerapi/swagger-ui | ForEach-Object {docker $dkrRemote rm $_ -f} ## specific container type
    docker $dkrRemote rmi $(docker $dkrRemote images -f "dangling=true" -q) # cleanup dangling junk from Build process
    docker system prune # also kills all running containers and cleans-up dangling images and build cache
    docker logs $cid # See what test a container outputed, this works on containers that are no longer running to see what it did

    ## See whats running
    docker ps
    docker ps --no-trunc # expand the output so you can see it all

    ## list images
    docker $dkrRemote images # list local images
    docker search $name # name can be just a partial name
    docker search alpine # example, alpine is a very common base image to start with

    #region Common docker switches, Mostly Windows stuff this region
        # running with AD creds both build and run
        docker $dkrRemote run -it --security-opt "credentialspec=file://mpt-mssql-test.json" microsoft/windowsservercore
        docker build . --security-opt "credentialspec=file://mpt-mssql-test.json" -t arcgis:t2

        # run with a U of M IP, without this the Host does PAT.  Again build or run time
        docker run -it --network=Ext microsoft/windowsservercore
        docker build . --network=Ext -t arcgis:t2

        ##### Get IP of container
        (docker $dkrRemote inspect $($name) | ConvertFrom-Json).NetworkSettings.Networks[0].psobject.properties.Value.IPAddress  ## for static IP
        docker $dkrRemote exec $($name) powershell.exe '(Get-netadapter | Get-NetIPAddress -AddressFamily IPv4).IPAddress' ## for DHCP
    #endregion
#endregion

#region Push to Artifactory/Docker
    # docker tag <image name> {repo}.artifactory.umn.edu/<image name>
    # docker push {repo}.artifactory.umn.edu/<image name>
    ## Initial connection
    # docker login {repo}.artifactory.umn.edu
    # docker login oit-mpt-docker.artifactory.umn.edu
#endregion

#region Swagger
    docker run -it --rm -v ${pwd}:/docs swaggerapi/swagger-codegen-cli-v3:3.0.7 generate -i /docs/itac.yml -l python -o /docs/libs/python
    docker run --rm -d -p 80:8080 -e API_URL=https://mpt-swaggertest.azurewebsites.net/openapi.json swaggerapi/swagger-ui
    docker run --rm -d -p 80:8080 -e API_URL=https://mpt-swaggertest.azurewebsites.net/umn-ssl-cert-req.yaml swaggerapi/swagger-ui
    docker run --rm -d -p 80:8080 swaggerapi/swagger-ui
    Invoke-WebRequest https://mpt-swaggertest.azurewebsites.net/umn-ssl-cert-req.yaml -OutFile d.yaml
    docker run --rm -d -p 80:8080  swaggerapi/swagger-ui
    docker run --rm -d -p 81:8080 swaggerapi/swagger-editor
#endregion

#region Windows
    #region start a container and keep it running 
        $waitUrl = 'https://raw.githubusercontent.com/Microsoft/Virtualization-Documentation/master/windows-server-container-tools/Wait-Service/Wait-Service.ps1'
        $ps = "Invoke-WebRequest -Uri '$waitUrl' -OutFile 'c:\Wait-Service.ps1';c:\Wait-Service.ps1 -ServiceName WinRm -AllowServiceRestart"
        ($cid = docker $dkrRemote run -d $dockerArgs microsoft/windowsservercore powershell.exe -executionpolicy bypass $ps )
        docker $dkrRemote run -it $dockerArgs microsoft/windowsservercore
        #start with mount to local folder
        ($cid = docker $dkrRemote run -v C:\Users\tjsobeck\Documents\dockerMount:c:\docs -d $dockerArgs microsoft/windowsservercore powershell.exe -executionpolicy bypass $ps )
        ($name = (((docker $dkrRemote ps --no-trunc -a| Select-String $cid).ToString()).Normalize()).Split(" ")[-1]) # some commands only seem to work with the name, not CID

        ## copy file or folder to a container, for example a powershell script you want to run
        $cPath = 'C:\Users\ContainerAdministrator\Documents' ## path to where you want files on container
        $local = 'temp.zip' #whatever you want copied over
        docker $dkrRemote cp -L $local $cid`:$cPath
        # lets validate it copied over
        docker $dkrRemote exec $($name) powershell.exe -executionpolicy bypass "Get-ChildItem -Path $cPath"
        docker $dkrRemote exec $($name) powershell.exe -executionpolicy bypass "Get-ChildItem -Path c:\docs"
        ###
        # There are 3 ways to send commands to a container, each has its pros/cons
        # 1) use docker exec like above > docker $dkrRemote exec $($name) powershell.exe -executionpolicy bypass "<insertPS>"
        # this is great for doing a few small things.  
        # This host will evaluate variables FIRST, THEN send the command.  Use SINGLE QUOTES if you want the container to evaluate the variable, such as 
        # ps> docker $dkrRemote exec $($name) powershell.exe -executionpolicy bypass '$env:COMPUTERNAME' # this will spit out the containers name
        #
        # 2) The second way is Invoke-Commnad, this only works from the container host, its better for running more complicated code, however you may be 
        # better off copying over a powershell scirpt with all the code and running it on the container.  That being said, below will run invoke-command
        Invoke-Command -ContainerId $cid -RunAsAdministrator -ScriptBlock{
            Get-ChildItem "$using:cPath"
            ## insert whatever you want here
        }
        #
        # 3) the third method is to enter a pssession.  This is great for just playing around and figuring stuff out
        # ps> Enter-PSSession -ContainerId $cid -RunAsAdministrator # connect to container
        ###
    #endregion
        docker run --rm -it  mcr.microsoft.com/powershell:alpine-3.8
    #region Load up some modules
        $ps = "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:`$false;`
                    Install-Module -Name VMware.PowerCLI,UMN-SCCM,UMN-Infoblox,UMN-Google,UMN-Github -Force -Confirm:`$false;"
        docker $dkrRemote exec $($name) powershell.exe -executionpolicy bypass $ps
        docker $dkrRemote exec $($name) powershell.exe -executionpolicy bypass "get-module -listavailable"
    #endregion

    #region Test a chocolatey package
        $chocoPack = 'splunk-mpt'
        $version = '--version 1.0.0'
        $waitTime = # [int] in seconds as estimate of how long package install takes
        $waitUrl = 'https://raw.githubusercontent.com/Microsoft/Virtualization-Documentation/master/windows-server-container-tools/Wait-Service/Wait-Service.ps1'
        $ps = "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));choco install $chocoPack $version -s 'http://oit-choco-web.ad.umn.edu/choco/nuget/' -y;Invoke-WebRequest -Uri '$waitUrl' -OutFile 'c:\Wait-Service.ps1';c:\Wait-Service.ps1 -ServiceName WinRm -AllowServiceRestart"
        ($cid = docker run -d $dockerArgs microsoft/windowsservercore powershell.exe -executionpolicy bypass $ps )
        Start-Sleep -Seconds $waitTime
        Invoke-Command -ContainerId $cid -RunAsAdministrator -ScriptBlock{
            Get-Content C:\choco\logs\choco.summary.log
            #Get-Content C:\choco\logs\chocolatey.log
            choco list --local-only ## list install packages
        }
        Enter-PSSession -ContainerId $cid -RunAsAdministrator
    #endregion

    #region DSC Pull Server Config testing -- super handy
        $ps = "Invoke-WebRequest -Uri 'http://oit-choco-web.ad.umn.edu/Data/Wait-Service.txt' -OutFile 'c:\Wait-Service.ps1';c:\Wait-Service.ps1 -ServiceName WinRm -AllowServiceRestart"
        ($cid = docker run -d $dockerArgs microsoft/windowsservercore powershell.exe -executionpolicy bypass $ps )
        $base = 'C:\Users\ContainerAdministrator\Documents'
        $o_path = 'C:\Users\oittjsobeck\Documents\GitHub\Docker\Images\'
        $mof = "$o_path\localhost.meta.mof"
        docker cp -L $mof $cid`:$base
        Invoke-Command -ContainerId $cid -RunAsAdministrator -ScriptBlock{
            Set-DscLocalConfigurationManager -Path 'C:\Users\ContainerAdministrator\Documents' -ComputerName 'localhost' -Verbose -Force
            Start-Sleep -Seconds 2
            Update-DscConfiguration
        }
    #endregion

    #region Test DSC local
        Set-Location 'C:\Users\tjsobeck\Documents\GitHub\Docker\Images\<folder>' # Cd into where ever you folder with dockerfile is.
        # build image based off dockerfile.  should have DSC in a powershell file that gets called
        $buildArgs = '' # optional
        $image = '' #lowercase
        docker build . $buildArgs -t $image
        ($cid = docker run -d $buildArgs $image powershell.exe -executionpolicy bypass c:\Wait-Service.ps1 -ServiceName WinRm -AllowServiceRestart) # run it to test
    #endregion
#endregion

#region Linux
    #region Python Linux
        # centos only runs python2.7 so use the 'python' container to get python3
        ## create a docker file with required modules and your script
        ## dockerfile 
        <#
            FROM python:3
            WORKDIR /usr/src/app
            COPY requirements.txt ./
            RUN pip install --no-cache-dir -r requirements.txt
            COPY . .
            CMD [ "python", "./your-daemon-or-script.py" ]
        #>
        docker build -t my-python .
        docker build -t umn-comodo .
        docker run -it --rm --name my-running-app my-python-app

        # run single script
        docker run -it --rm --name my-running-script -v "<localPath>":/usr/src/myapp -w /usr/src/myapp python:3 python your-daemon-or-script.py
        $lpath = ""
        docker run -it --rm --name my-running-script -v ${lpath}:/usr/src/myapp -w /usr/src/myapp python python t.py
        docker run -it --rm -v ${pwd}:/usr/src/myapp -w /usr/src/myapp my-python python call-LPT-Add-vmware-info.py
    #endregion

    #region Get SSL Cert
        $login = 'oit-platforms';$pswd = '';$unitName = 'VIRT'; $cn = 'vc-test01.oit.umn.edu'; $email = ''; $certPSWD = '3'; $platform = 'linux'
        #test 
        docker run -it --rm --name mycomodo umn-comodo python cert_get_certTypes.py --login $login --pswd $pswd
        #
        Single domain
        docker run -it --rm --name mycomodo -v ${pwd}:/usr/src/app/out umn-comodo python cert.py --login $login --pswd $pswd --unitName $unitName --cn $cn --email $email --certPSWD $certPSWD --platform $platform
        Multi-domain
        docker run -it --rm --name mycomodo -v ${pwd}:/usr/src/app/out umn-comodo python cert.py --login $login --pswd $pswd --unitName --cn --email --certPSWD --platform --altNames
    #endregion

    #region Centos
        $lpath = "$($env:USERPROFILE)\Desktop\dockerMount\"
        docker run -it --rm --name my-centos -v ${lpath}:/home -w /home mycentos
    #endregion

    #region mysql
        $dbRootCreds = Get-Credential
        docker run -d --name=mysql1 -e MYSQL_ROOT_PASSWORD=$($dbRootCreds.GetNetworkCredential().Password) -p 3306:3306 mysql
    #endregion

    #region ITAC
        
        docker run -d --name=itacdb -p 3306:3306 itac-db
    #endregion

    #region Groovy
        $sqlCred = Get-Credential
        $grouperPswd = Get-Credential
        $ldapCred = Get-Credential
        $ldapHost = ''
        $dockerPath = ''
        $sqlServer = ''
        docker run -it --rm --name grvy -v ${dockerPath}\myGroovy:/home/groovy/scripts -v grapes-cache:/home/groovy/.groovy/grapes -w /home/groovy/scripts `
            -e SQL_SERVER=$($sqlServer) -e SQL_USER=$($sqlCred.UserName) -e SQL_PSWD=$($sqlCred.GetNetworkCredential().Password) `
            groovy groovy sql.groovy

        docker run -it --rm --name grvy -v ${dockerPath}\myGroovy:/home/groovy/scripts -v grapes-cache:/home/groovy/.groovy/grapes -w /home/groovy/scripts `
            -e LDAP_HOST=$($ldapHost) -e LDAP_USER=$($ldapCred.UserName) -e LDAP_PASS=$($ldapCred.GetNetworkCredential().Password) `
            groovy groovy ldap.groovy

        docker run -it --rm --name grvy -v ${dockerPath}\myGroovy:/home/groovy/scripts -v grapes-cache:/home/groovy/.groovy/grapes -w /home/groovy/scripts `
            -e CLIENT_ID=$($oauthClientId) `
            groovy groovy auth-main.groovy #goauth-old.groovy #
    #endregion

    #region Gradle
        $sqlCred = Get-Credential
        $ldapCred = Get-Credential     
        $projPath = ''

        docker run --rm -v ${projPath}:/home/gradle/project -w /home/gradle/project `
            -e SQL_SERVER=$($sqlServer) -e SQL_USER=$($sqlCred.UserName) -e SQL_PSWD=$($sqlCred.GetNetworkCredential().Password) `
            -e LDAP_HOST=$($ldapHost) -e LDAP_USER=$($ldapCred.UserName) -e LDAP_PASS=$($ldapCred.GetNetworkCredential().Password) `
            gradle gradle test --stacktrace

        docker run --rm -v ${projPath}:/home/gradle/project -w /home/gradle/project `
            -e SQL_SERVER=$($sqlServer) -e SQL_USER=$($sqlCred.UserName) -e SQL_PSWD=$($sqlCred.GetNetworkCredential().Password) `
            -e LDAP_HOST=$($ldapHost) -e LDAP_USER=$($ldapCred.UserName) -e LDAP_PASS=$($ldapCred.GetNetworkCredential().Password) `
            gradle gradle wrapper

        docker run --rm -v ${projPath}:/home/gradle/project -w /home/gradle/project `
            -e SQL_SERVER=$($sqlServer) -e SQL_USER=$($sqlCred.UserName) -e SQL_PSWD=$($sqlCred.GetNetworkCredential().Password) `
            -e LDAP_HOST=$($ldapHost) -e LDAP_USER=$($ldapCred.UserName) -e LDAP_PASS=$($ldapCred.GetNetworkCredential().Password) `
            gradle ./gradlew build --stacktrace | Tee-Object -Variable capping 
            $capping | Select-String -Pattern ".*at (org|groovy|sun).*" -NotMatch
            # dumps file C:\Users\travis\Documents\GitHub\oit-api\itac\build\libs\itac.war
        
        docker build $projPath -t tjsacs.azurecr.io/itac-api
        az acr login --name tjsacs
        docker push tjsacs.azurecr.io/itac-api
        docker $dkrRemote ps -aq | ForEach-Object {docker $dkrRemote rm $_ -f} ## Kill all running containsers
        docker run --name tomcat -d -v ${projPath}\build\libs\itac.war:/usr/local/tomcat/webapps/itac.war -p 8080:8080 `
            -e SQL_SERVER=$($sqlServer) -e SQL_USER=$($sqlCred.UserName) -e SQL_PSWD=$($sqlCred.GetNetworkCredential().Password) `
            -e LDAP_HOST=$($ldapHost) -e LDAP_USER=$($ldapCred.UserName) -e LDAP_PASS=$($ldapCred.GetNetworkCredential().Password) `
            tomcat
            #itac-api `
            
        
            # Generate client libs/sdks
            $v = "$($projPath)\src\main\swagger"
            docker run -it --rm -v ${v}:/docs swaggerapi/swagger-codegen-cli-v3:3.0.7 generate -i /docs/itac.yml -l python -o /docs/libs/python
            docker run -it --rm -v ${pwd}:/docs azuresdk/autorest autorest --powershell --input-file:/docs/itac.yml

        # Test Calls
            docker $dkrRemote ps -aq | ForEach-Object {docker $dkrRemote rm $_ -f} ## Kill all running containsers
            ($r = (Invoke-WebRequest -Uri 'http://localhost:8080/itac/v0/groups/VIRT').Content | ConvertFrom-Json)
            ($r = (Invoke-WebRequest -Uri 'http://localhost:8080/itac/v0/units/VIRT').Content | ConvertFrom-Json)
            (Invoke-WebRequest -Uri 'http://localhost:8080/itac/v0/groups/VIRT?getUsers=true').Content | ConvertFrom-Json
            (Invoke-WebRequest -Uri 'http://localhost:8080/itac/v0/units?lid=D00005').Content | ConvertFrom-Json
            (Invoke-WebRequest -Uri 'http://localhost:8080/itac/v0/units' -Method Patch -Body (@{unit='VIRT'; unit_name='Virtual Infrastructure'} | ConvertTo-Json) -ContentType 'application/json').Content | ConvertFrom-Json
            Invoke-WebRequest -Uri 'http://localhost:8080/itac/v0/units/VIRT/contact/noreplyumn.edu' -Method DELETE 
    #endregion

    #region node.js
        docker run -p 3000:3000 -v /app/node_modules -v ${pwd}:/app nexxus916/frontend 
        docker run nexxus916/frontend npm run test -- --coverage
        # if you use the -v flag with only the one half, it means DON'T try to map that one specific folder to your local machine, use what's in the container
    #endregion

#endregion

#region Install Chef on Windows
    $name = (((docker $dkrRemote ps --no-trunc -a| Select-String $cid).ToString()).Normalize()).Split(" ")[-1]
    $ps1 = 'Invoke-WebRequest -uri "https://omnitruck.chef.io/install.ps1" -OutFile c:\install.ps1;c:\install.ps1;Install'
    docker $dkrRemote exec  $($name) powershell.exe -executionpolicy bypass $ps1
    ## 
    ## Test chef cookbook locally on container
    $cPath = 'c:\chef'
    $local = 'C:\Users\oittjsobeck\Documents\GitHub\Chef\Testing\'## where ever the cookbooks are
    docker $dkrRemote cp -L $local $cid`:$cPath
    docker $dkrRemote exec  $($name) powershell.exe -executionpolicy bypass 'cd c:\chef;chef-client -z -r "recipe[IIStest]' ## repalce IIStest with your cookbook

    ## Connect node to chef server
    $chefURL = 'https://chef-test.oit.umn.edu/organizations/oit-mpt'
    $chefURL = 'https://chef.umn.edu/organizations/oit-mpt'
    $validationClientName = ''
    # the node needs one file
    $local = 'C:\Users\oittjsobeck\Documents\GitHub\Chef\chef-tst\.chef\oit-mpt-validator.pem'
    docker $dkrRemote cp -L $local $cid`:'C:\chef\validation.pem'

    $cname = ($cid.Substring(0,12)).toupper()
@"
chef_server_url  '$chefURL'
validation_client_name '$validationClientName'
file_cache_path   'c:/chef/cache'
file_backup_path  'c:/chef/backup'
cache_options     ({:path => 'c:/chef/cache/checksums', :skip_expires => true})
node_name '$cname'
log_level        :info
log_location       STDOUT
"@ | Out-File "$cname.rb" -Encoding utf8 -Force
    docker $dkrRemote cp -L "$cname.rb" $cid`:"c:\chef"
    #docker $dkrRemote cp -L "first-boot.json" $cid`:"c:\chef"
    Remove-Item "$cname.rb" -Force # once its on the container we don't need it any more
    docker $dkrRemote  exec $($name) powershell.exe -executionpolicy bypass "chef-client -c c:/chef/$cname.rb" # -j c:/chef/first-boot.json"

    ########## This only works from the Container Host
    Invoke-Command -ContainerId $cid -RunAsAdministrator -ScriptBlock{
@"
chef_server_url  '$using:chefURL'
validation_client_name '$using:validationClientName'
file_cache_path   'c:/chef/cache'
file_backup_path  'c:/chef/backup'
cache_options     ({:path => 'c:/chef/cache/checksums', :skip_expires => true})
node_name '$env:COMPUTERNAME'
log_level        :info
log_location       STDOUT
"@ | Out-File 'c:\chef\client.rb' -Encoding utf8 -Force
    chef-client -c c:/chef/client.rb -j c:/chef/first-boot.json
    }

    $name = (((docker ps --no-trunc -a| Select-String $cid).ToString()).Normalize()).Split(" ")[-1]
    $ps = "get-content c:\chef\client.rb"
    docker exec $($name) powershell.exe -executionpolicy bypass $ps
    $ps = "get-content c:\chef\first-boot.json"
    docker exec $($name) powershell.exe -executionpolicy bypass $ps

    ################################## End Install Chef ##################################
#endregion

#region random stuff
    # cd into folder with dockerfile and scripts etc
    $buildArgs = '' # optional
    $image = '' #lowercase
    docker build . $buildArgs -t $image
    ($cid = docker run -d $buildArgs $image powershell.exe -executionpolicy bypass c:\Wait-Service.ps1 -ServiceName WinRm -AllowServiceRestart)

    docker build . --network=Ext -t chocotester
    docker build . --no-cache --network=Ext --security-opt "credentialspec=file://mpt-mssql-test.json" -t arcgis:t2
    docker build . --no-cache --network=Ext  -t pulltest

    docker run -d --network=Ext --security-opt "credentialspec=file://mpt-mssql-test.json" test2
    docker run -d --network=Ext arcgis powershell.exe -executionpolicy bypass c:\Wait-Service.ps1 -ServiceName WinRm -AllowServiceRestart
    docker run -d --network=Ext --security-opt "credentialspec=file://mpt-mssql-test.json" microsoft/windowsservercore
    ($cid = docker run -d --network=Ext --security-opt "credentialspec=file://mpt-mssql-test.json" arcgis:t2 powershell.exe -executionpolicy bypass c:\Wait-Service.ps1 -ServiceName WinRm -AllowServiceRestart)

#endregion

#region Certificates
<#
    ## run all on any machine will openssl
    ## See HostConfig for example deamon file and certs
    ---server
    openssl genrsa -aes256 -out ca-key.pem 4096
    openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
    openssl genrsa -out server-key.pem 4096
    openssl req -subj "/CN=" -sha256 -new -key server-key.pem -out server.csr
    echo subjectAltName = DNS: >> extfile.cnf
    echo extendedKeyUsage = serverAuth >> extfile.cnf
    openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf

    ---client
    openssl genrsa -out key.pem 4096
    openssl req -subj '/CN=client' -new -key key.pem -out client.csr
    echo extendedKeyUsage = clientAuth > extfile.cnf
    openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile.cnf
    cert.pem,key.pem,cat.pem all go in c:\users\<user>\.docker
    client calls use docker --tlsverify # --tlsverify does not work if you try to put it in a string variable
#>
#endregion

#region Container host set-up notes ##################################
    # See Certificates regioin above
    $name = ''
    $dns = ''
    $svc = ''
    $grp = ''
    $containerHost = ''

    New-ADServiceAccount -name $name -DnsHostName $dns  -ServicePrincipalNames $svc/$dns -PrincipalsAllowedToRetrieveManagedPassword $grp

    $name = ''
    $dns = ''
    $svc = 'http'
    New-ADServiceAccount -name $name -DnsHostName $dns  -ServicePrincipalNames $svc/$dns -PrincipalsAllowedToRetrieveManagedPassword $grp

    Invoke-Command -ComputerName $containerHost -Credential (Get-Credential) -ScriptBlock{ ## this must run as Domain Admin
        Install-ADServiceAccount $using:name
    }

    Install-ADServiceAccount -Identity ''
    New-CredentialSpec -Name '' -AccountName ''
#endregion

