# Gemfire module session with tomcat

## Topology

The module session embedded in tomcat would enable the http session stored in a gemfire data fabric instead of the tomcat. 
Current implementation supports gemfire client server topology.

## Gemfire module session bindary package
The buildpack needs to download the gemfire module session binary package from a public repo. Due to proprietary of gemfire software, we are not able to publish the package to the public repo. Detailed repo setup can be provided upon request

## Example

* Have a gemfire server and locator running
* Upload this buildpack to your cloudfoundry

  ```
  bundle exec rake package
  cf create-buildpack gemfire-session build/$build-pack.zip 100
  ```
* Create a user defined service in cloudfoundry

  ```
  cf create-user-provided-service session-gemfire-replication -p '{"locator":"192.168.62.1","port":"10334"}'
  ```
* bind the service to your app

  ```
  cf bind-service $APP_NAME session-gemfire-replication
  ```
* push your app with new buildpack

  ```
  cf push $APP_NAME -p $war_file -b gemfire-session
  ```
