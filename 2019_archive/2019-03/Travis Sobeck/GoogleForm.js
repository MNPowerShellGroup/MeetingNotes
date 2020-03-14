function submitToAzure(e){
    var s = SpreadsheetApp.getActiveSheet();
     var header = s.getRange(1,1,1,s.getLastColumn()).getValues()[0];
     var data = {};
     data['email'] = e.values[1];
     for(i=0; i < header.length; i++)
     {
        data[header[i]]= e.values[i];
     }
       
     // send request to Azure Runbook to build server
     var url = '<runbookWebhook>'; // Get this when you create a webhook for a runbook in AZure or wherever you endpoint is.
     var options = {
      'method' : 'post',
      'contentType': 'application/json',
       'payload' : JSON.stringify(data)
     };
     var response = UrlFetchApp.fetch(url, options);
     Logger.log(JSON.parse(response.getContentText()).JobIds);
     
   }