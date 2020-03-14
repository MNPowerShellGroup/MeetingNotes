FROM mcr.microsoft.com/powershell:6.2.3-alpine-3.8
RUN pwsh -c "Install-Module universaldashboard -Acceptlicense -Force"
EXPOSE 8085
COPY [ "./example.ps1", "/home/example.ps1" ]
ENTRYPOINT ["pwsh", "/home/example.ps1"]
