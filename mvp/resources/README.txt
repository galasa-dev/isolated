IBM Distribution for Galasa version 1.0  
===============================================================================    

Overview       
------------  
                                                                                                              
Start using Galasa to enable deep integration testing across platforms and technologies, and run 
repeatable, reliable, agile testing at scale across your enterprise.  

This zip enables a network-free installation of Galasa, removing the requirement to connect to the 
internet when building or running tests.

This zip file contains:                                                                                                                             
    - An eclipse directory containing the Galasa plug-in                                                                                                
    - A maven directory containing dependencies that are required for building Galasa tests                                                             
    - A javadoc directory containing javadoc API documentation for the Galasa Managers                                                                                                                              
    - An isolated.tar file - an optional Docker image that hosts the Eclipse and Maven directories. Use this file to host Galasa                        
    on an internal server that can be accessed by other users.                                                                                          
    - A docs.jar file that enables you to run the Galasa website locally on your machine                                                                
    - IBM Distribution for Galasa 1.0 Notices.html                               
    - Software license files in different languages                                                                       
                                                                                                 
                                                                                                                                                    
You can find out more about Galasa on the Galasa website https://galasa.dev, or you can host the website locally by 
running the `docs.jar` file that is contained in this zip file on your machine or on an internal server.                                                                

Running the website on your local machine
-------------------------------------------

From a command line, run the following command in the directory in which you extracted the download 
containing the `docs.jar` file: 

`java -jar docs.jar`

The URL to view the locally hosted documentation is returned: http://localhost:9080/


Running the Galasa website on an internal server
----------------------------------------------------
 
To host the website on an internal server so that it can be accessed by other users, set the host 
system properties or environment variables to bind to an externally available network interface, 
rather than localhost. For example: 

`java -Dserver.http.port=12345 -jar docs.jar` or `SERVER_HTTP_HOST=example.com java -jar docs.jar`

 
Getting started 
--------------------                                                                                                                 
                                                                                                                                                   
For information about installing the Galasa plug-in and getting started with using Galasa, go 
to the "Docs > Getting started" documentation on the Galasa website. 

Note that the Galasa Ecosystem is not supported in IBM Distribution for Galasa version 1.0.

The locally run website currently links to the external Javadoc site. You can access the Javadoc 
locally by using the Javadoc documentation that is contained in the Javadoc directory provided in this zip. 


Notes
--------------------  

You are responsible for any sensitive information that you put into any configuration files. 

IBM Knowledge Centre
-----------------------                                                                                                                                
                                                                                                                           
For information about using IBM Z Virtual Test Platform and IBM Distribution for Galasa to automate your testing, see the IBM Z Virtual Test Platform documentation at:                      
https://www.ibm.com/docs/zvtp 
                                                                                                                    
                                                                                                                      
                                                                                                                                                    
                                                                                                                                                    
*******************************************************************************     

(c) Copyright IBM Corp. 2021.                                                                                        
                                                                          
*******************************************************************************                                                                     
