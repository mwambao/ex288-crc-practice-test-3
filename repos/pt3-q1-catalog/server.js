const http=require('http'); const port=8080; http.createServer((req,res)=>{res.writeHead(200,{'Content-Type':'text/plain'});res.end('Catalog service - Practice Test 3\n')}).listen(port,'0.0.0.0');
