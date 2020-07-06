/*
import http from 'http'
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

/*import OraclesServer from './server';

 
 var http = require('http');
 var server = http.createServer(function(request, response){

    
    }); //end server
 server.listen(3000,'127.0.0.1');
 console.log('Oracles Server up and running');
*/

import http from 'http'
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
