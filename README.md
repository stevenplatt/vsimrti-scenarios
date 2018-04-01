VSimRTI v17 and Simulation Scenarios
------------------------------------
A central repository to hold vehicle network simulation data and scenario configuration.
Custom application tests in JAR format will also be stored in this location.

This ReadMe file will be updated with summaries as additional simulation scenarios are added.
When using VSimRTI - note that a license file has to be requested from the makers of VSimRTI before the simulations will run.

Running Simulations
-------------------


Running Portable Simulations in the Browser
-------------------------------------------

For the most portable and reproducible environment, use the package Docker image of Ubuntu to GUI.
The Ubuntu Docker image runs in the browser and includes installations of JDK, Git, and other components to make downloading, running, reproducing, and sharing simulation data easier.

Find it at Docker Hub, here: https://hub.docker.com/r/telecomsteve/vsimrti-web/
```
sudo docker pull telecomsteve/vsimrti-web
```
Run the Docker image with:
```
docker run -it --rm -p 6080:80 telecomsteve/vsimrti-web
```
Connect to the web instance at localhost address: http://127.0.0.1:6080/

![screenshot](https://raw.github.com/stevenplatt/docker-vsimrti-web/master/screenshots/vsimrti-web.jpg?v1)
