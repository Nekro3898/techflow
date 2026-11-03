const http = require('node:http');

const port = Number(process.env.PORT) || 3000;

const server = http.createServer((request, response) => {
  if (request.method === 'GET' && request.url === '/') {
    response.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    response.end('<!doctype html><html lang="es"><meta charset="utf-8"><title>Techflow</title><h1>Servidor Node activo</h1></html>');
    return;
  }

  response.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
  response.end('No encontrado');
});

server.listen(port, () => {
  console.log(`Servidor iniciado en http://localhost:${port}`);
});