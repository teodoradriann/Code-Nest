#CODE NEST

Code Nest is a minimal code editor which allows users to run Swift code very fast without hassle.
The application offers real-time output, syntax highlighting, and easy navigation to the errors.
Code Nest implements basic functionalities like saving the current code and load another code file into the editor.

It uses multithreading which allows the application to run the program on parallel so the editor remains fully functional while running a code. 
It's also very memory efficient, any cases of infinite loops which lead to memory corruption are being automatically detected and the process is automatically shut down to prevent
the app from turning unresponsive. 


##IMPORTANT
In order to run the code within the app you need to disable the App Sandbox, by going to the project Signing & Capabities and delete App Sandbox.
