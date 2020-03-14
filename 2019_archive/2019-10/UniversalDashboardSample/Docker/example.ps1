Write-Host "Starting Demo Dashboard..."

Try{
    # simple static get
    $Endpoint = New-UDEndpoint -Url "/thing" -Method "GET" -Endpoint {
        @{key="value"}  | ConvertTo-Json
    }
    # take in variable as part of the path
    New-UDEndpoint -Url "/thing2/:id" -Method "GET" -Endpoint {
        param($id)
    
        @{yousent=$id}  | ConvertTo-Json
    }
    # there is some regex but I"m skipping

    # post with specifically defined inputs, the body should be something like  @{arg1="yarb";arg2="supbro"}
    New-UDEndpoint -Url "/thing3" -Method "POST" -Endpoint {
        param($arg1, $arg2)
   
        @{$arg1=$arg2}  | ConvertTo-Json
   }

   # post that takes in standard json in the body (free form)
    New-UDEndpoint -Url "/thing4" -Method "POST" -Endpoint {
        param($body)

        $input = $body | ConvertFrom-Json
        # shoot input back out
        $input | ConvertTo-Json
    }

    # this will enable all the defined endpoints
    Start-UDRestApi -Endpoint $Endpoint -Port 8085 -wait
}
Catch{
    Write-Host "UniversalDashboard failed to start!"
}