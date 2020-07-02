import OraclesServer from './server';

 
 var http = require('http');
 var server = http.createServer(function(request, response){

    // Instantiate oracles server:
    let oraclesServer = new OraclesServer('localhost', () => {
        // Server boot-up message:
            response.writeHead(200, {'Content-Type':'text/html'});
            let oraclesCount = 0; //OraclesCount
            oraclesServer.oraclesCount((OC)=>{
                oraclesCount = OC;
                console.log(oraclesCount);
                });
            var message = '<h1>Oracles Server</h1>'+
                '<h3>Setting up '+ oraclesCount + ' oracles for fetching flight status:</h3>';
            response.end(message);

            message = ''; // reset server message
            console.log(message)  ;
            
            response.writeHead(200, {'Content-Type':'text/html'});
            response.end(message);
        
        }); //end oraclesServer
    }); //end server
 server.listen(3000,'127.0.0.1');
 console.log('Oracles Server up and running');


/*import http from 'http'
import app from './server'

const server = http.createServer(app)
let currentApp = app
server.listen(3000)

if (module.hot) {
 module.hot.accept('./server', () => {
  server.removeListener('request', currentApp)
  server.on('request', app)
  currentApp = app
 })
}
*/