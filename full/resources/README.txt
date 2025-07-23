Overview
------------

Start using Galasa to enable deep integration testing across platforms and technologies, and run 
repeatable, reliable, agile testing at scale across your enterprise.  

This zip enables a network-free installation of Galasa, removing the requirement to connect to the 
internet when building or running tests.

This zip file contains:
    - A maven directory containing dependencies that are required for running Galasa tests.
    - A javadoc directory containing javadoc API documentation for the Galasa Managers.
    - A galasactl directory containing the binaries of the Galasa CLI.
    - A docs.tar file that loads a Docker image, which enables you to run the Galasa website
      locally on your machine or on an internal server.
    - An isolated.tar file - an optional Docker image that hosts the Maven directories.
      Use this file to host Galasa on an internal server that can be accessed by other users.


You can find out more about Galasa on the Galasa website https://galasa.dev, or you can host the website
locally by following the instructions in the section below to run a web server on your machine.


Pre-requisites
----------------

- Java 11 or above to run Galasa tests. Currently Java 21 or above is not supported.
- Docker - If you want to load and run the Docker images provided in this zip, you will need Docker installed.


Running the website on your local machine
-------------------------------------------

Note: The example uses port `9080` but you can use a different port.

From a command line, run the following command in the directory in which you extracted the download 
containing the `docs.tar` file: 

`docker load -i  docs.tar`

The following confirmation message is received: `Loaded image: ghcr.io/galasa-dev/galasa-docs-site:main`.

Then, run the container by using the following command:

`docker run -d -p 9080:80 --name galasa-docs-site ghcr.io/galasa-dev/galasa-docs-site:main`

The URL to view the locally hosted documentation is: http://localhost:9080/


Running the Galasa website on an internal server
----------------------------------------------------
 
To host the website on an internal server so that it can be accessed by other users, you can 
run the Docker container on a known port and bind to a host IP address, rather than localhost.

For example, replace `192.168.1.100` with your internal server’s private IP address, and run:

`docker run -d -p 192.168.1.100:9080:80 --name galasa-docs-site ghcr.io/galasa-dev/galasa-docs-site:main`

Now your site is accessible to other users on the same network using that IP and port.

 
Getting started
--------------------

For information about installing and using the Galasa CLI and getting started with using Galasa, go 
to the "Docs > Getting started using the Galasa CLI" documentation on the Galasa website. 

The locally run website currently links to the external Javadoc site. You can access the Javadoc 
locally by using the Javadoc documentation that is contained in the Javadoc directory provided in this zip. 


Notes
--------------------

You are responsible for any sensitive information that you put into any configuration files. 