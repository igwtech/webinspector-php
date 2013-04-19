webinspector-php
================

A PHP Debugger interface using XDebug and WebKit's WebInspector

I always have though that WebInspector is a great graphical debugging interface. Since PHP is so highly deployed I though
it could make a great combination to use it to debug PHP. 
FirePHP and ChromePHP try to bridge the gap between WebInspector and PHP but neither allow you to step thru the code
or inspect variables. This development does exactly that.

It has been develop thanks to the following great open-source projects:
 - XDebug: http://www.xdebug.org
 - NodeJS: http://www.nodejs.org
 - HaXe: http://www.haxe.org
 - HaXe NodeJS: http://lib.haxe.org/p/nodejs
 - Chromium: http://www.chromium.org/

What works:
 - Code stepping
 - Breakpoints
 - Variable inspection

What's missing:
 - Stack traces
 - Console output
 - Expression evaluation
 - More documentation
 - Watched Expressions


How to use?
==========

Requirements:
-------------

To run this tool you require of:
- A Webserver (I usually use Apache but it should work with any PHP supported webserver: IIS, ngix, Lighttpd, etc)
- PHP 5.2 or better
- XDebug extension for PHP
- NodeJS with the modules: connect, websocket & xml2js

To compile the code you additionally will need:
- HaXe 2.10
- HaXe libraries:
  - nodejs_std
  - nodejs_externs

How to install?:
----------------

Configure your Webserver with PHP, if you use a Debian based linux distro this is very simple aptitude.

    # sudo apt-get install apache2 php5 libapache2-mod-php5
    
Install and configure XDebug on your webserver.

    # sudo apt-get install php5-xdebug

After installing, we need to customize the XDebug configuration. Append the following lines to /etc/php5/conf.d/xdebug.ini:

    [xdebug]
    ; enable debugger
    xdebug.remote_enable=1
    xdebug.remote_handler=dbgp
    xdebug.remote_host=localhost
    xdebug.remote_port=9000
    ; Uncomment the following line start the debugger automatically with navigating any PHP page.
    ; xdebug.remote_autostart = 1

Restart your webserver so it will take the new configuration:

    # sudo /etc/init.d/apache2 restart

Now install NodeJS, for that go to http://nodejs.org/download/ and download the package for your distro.
  You can find instructions for almost any platform at: 
  
> https://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager

Get the debugServer js compiled source:

    # mkdir ~/debugServer
    # cd ~/debugServer
    # wget https://raw.github.com/igwtech/webinspector-php/master/NodeMain.js

Install the node modules required using the Node Package Manager (npm):

    # cd ~/debugServer
    # npm install connect websocket xml2js

Run the debugServer in NodeJS:

    # node NodeMain.js

The debugServer will create a listening socket on port 9000 for XDebug to connect to and a WebServer on port 8080 where the WebInspector interface will be served.

Open your browser and point it to: 

>  http://localhost:8080/devtools/devtools.html?ws=localhost:8080/debugger

Now open another Browser window and point it to your PHP site on your webserver passing the XDEBUG Session parameter, for example:

>  http://localhost/phpsite/index.php?XDEBUG_SESSION_START=foobar

You will get an automatic breakpoint on your WebInspector Browser window with the PHP source code.

Profit!

Note: You need to open/reload the browser windows in the order mentioned to start a debugging session on WebInspector.
    
How to compile?:
----------------

Install Haxe 2.10, and using haxelib install the dependencies:

    # sudo haxelib install nodejs_std
    # sudo haxelib install nodejs_externs
 
A HXML is included in the code, download it using Git and compile simple by running:

    # haxe debugServer.hxml

Feel free to step in and help!

LICENSE
-------
Licensed under GPLv2
