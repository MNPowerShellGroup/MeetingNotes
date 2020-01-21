#FROM mcr.microsoft.com/powershell:latest
FROM mcr.microsoft.com/powershell:6.2.3-alpine-3.8
LABEL description="Based on the Microfot Ubuntu 18.04 for Linux PowerShell Dockerfile that will download and start Universal Dashboard Community on port 8080" 
RUN pwsh -c "Install-Module universaldashboard -Acceptlicense -Force"
EXPOSE 8085
COPY [ "./example.ps1", "/home/example.ps1" ]
ENTRYPOINT ["pwsh", "/home/example.ps1"]
