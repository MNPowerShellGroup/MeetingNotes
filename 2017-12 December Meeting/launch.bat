@echo off
@echo log_level :info > c:\chef\client.rb
@echo log_location STDOUT >> c:\chef\client.rb
@echo chef_server_url '%2/organizations/%1' >> c:\chef\client.rb
@echo validation_client_name '%1-validator' >> c:\chef\client.rb
@echo validation_key '\chef\%1-validator.pem' >> c:\chef\client.rb
@echo ssl_verify_mode :verify_none >> c:\chef\client.rb
@echo interval 600 >> c:\chef\client.rb
@echo environment %3 >> c:\chef\client.rb

@echo { > c:\chef\node.json
@echo     "run_list": [ >> c:\chef\node.json
@echo       "role[%4]" >> c:\chef\node.json
@echo     ] >> c:\chef\node.json
@echo } >> c:\chef\node.json
